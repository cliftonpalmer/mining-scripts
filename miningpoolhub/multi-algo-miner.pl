#!/usr/bin/perl -s
# Mines using multi-algo switching on MiningPoolHub
use strict;
use warnings;

use JSON;
use Data::Dumper;

use vars qw( $debug $user );
$debug = 0 unless $debug;
die "Need user" unless $user;

# get available algorithms from ccminer
my @ccminer_algos = split "\n", `ccminer -h | awk '\$1 == "-d," {exit} p {print \$1} \$1 == "-a," {p++}'`;
print Dumper(\@ccminer_algos) if $debug > 1;

################################################################################
# subs
################################################################################
sub get_stats {
	from_json(`curl -s "http://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics"`)
}

################################################################################
sub get_algo_to_stat {
	my $stats = get_stats;
	my %algo_to_stat = ();

	for my $stat (@{$stats->{return}}) {
		my $algo = lc $stat->{algo};
		$algo_to_stat{$algo}{host} = $stat->{host};
		$algo_to_stat{$algo}{port} = $stat->{multialgo_switch_port};
	}

	return \%algo_to_stat;
}

################################################################################
sub get_ethminer_cmd {
	my ($host, $port) = @_;
	return "ethminer --farm-retries 0 -U -S $host:$port -O $user.`hostname`:x"
}

sub get_bminer_cmd {
	my ($host, $port) = @_;
	return "bminer -uri stratum+ssl://$user.`hostname`\@$host:$port -max-network-failures=0 -watchdog=false"
}

sub get_ccminer_cmd {
	my ($host, $port, $algo) = @_;
	return "ccminer -r 0 -a $algo -o stratum+tcp://$host:$port -u $user.`hostname` -p x"
}

################################################################################
# find whatever coin algorithm has the highest profit
# switch to mining that algorithm with ccminer
print "Starting CJ's multi-algo miner\n";
while (1) {
	print "Starting the parent loop\n";
	my $algo_to_stat = get_algo_to_stat;
	while (my ($algo, $stat) = each %$algo_to_stat) {
		my $host = $stat->{host};
		my $port = $stat->{port};
		my $cmd;

		# pick miner
		if ($algo eq 'ethash') {
			$cmd = get_ethminer_cmd($host, $port);
		}
		elsif ($algo eq 'equihash') {
			$cmd = get_bminer_cmd($host, $port);
		}
		elsif (grep { $_ eq $algo } @ccminer_algos) {
			$cmd = get_ccminer_cmd($host, $port, $algo);
		}

		# start child miner
		if ($cmd) {
			print "Starting child: $cmd\n";
			my $pid;
			die "fork: $!" unless defined ($pid = fork);
			exec $cmd unless $pid;
			waitpid $pid, 0;
		}
		else {
			print "Nothing can run this algorithm: $algo\n";
			sleep 60;
		}
	}
	sleep 1
}
