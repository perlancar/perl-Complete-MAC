package Complete::MAC;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_known_mac
               );

our $COMPLETE_MAC_TRACE = $ENV{COMPLETE_MAC_TRACE} // 0;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to MAC addresses',
};

$SPEC{'complete_known_mac'} = {
    v => 1.1,
    summary => 'Complete a known hostname',
    description => <<'_',

Complete from a list of "known" MAC addresses.

Known MAC addresses will be searched from: ifconfig output, ARP cache,
`/etc/ethers`.

_
    args => {
        %arg_word,
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_known_mac {
    my %args = @_;

    my %macs;

    # from ifconfig output (TODO: alternatively from "ip link show")
    {
        $log->tracef("[compmac] Checking ifconfig output") if $COMPLETE_MAC_TRACE;
        require IPC::System::Options;
        for my $prog ("/sbin/ifconfig") {
            next unless -x $prog;
            my @lines = IPC::System::Options::readpipe(
                {lang=>"C"}, "$prog -a");
            next if $?;
            for my $line (@lines) {
                if ($line =~ /^\s*HWaddr\s+(\S+)/) {
                    $log->tracef("[compmac]   Adding %s", $1) if $COMPLETE_MAC_TRACE;
                    $macs{$1}++;
                }
            }
            last;
        }
    }

    # from ARP cache (TODO: alternatively from "ip neigh show")
    {
        $log->tracef("[compmac] Checking arp -an output") if $COMPLETE_MAC_TRACE;
        require IPC::System::Options;
      PROG:
        for my $prog ("/usr/sbin/arp") {
            next unless -x $prog;
            my @lines = IPC::System::Options::readpipe(
                {lang=>"C"}, "$prog -an");
            next if $?;
            for my $line (@lines) {
                if ($line =~ / at (\S+) \[ether\]/) {
                    $log->tracef("[compmac]   Adding %s", $1) if $COMPLETE_MAC_TRACE;
                    $macs{$1}++;
                }
            }
            last PROG;
        }
    }

    # TODO: from /etc/ethers

    require Complete::Util;
    Complete::Util::complete_hash_key(word => $args{word}, hash=>\%macs);
}

1;
# ABSTRACT:

=for Pod::Coverage .+

=head1 ENVIRONMENT

=head2 COMPLETE_MAC_TRACE => bool

If set to true, will display more log statements for debugging.


=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.
