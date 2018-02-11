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
sub get_best_stat {
	my $stats = get_stats;
	my $best_stat;

	# get most profitable stat for nvidia cards
	for my $stat (@{$stats->{return}}) {
		$best_stat = $stat and next unless $best_stat;

		if ($stat->{profit} > $best_stat->{profit}) {
			$best_stat = $stat;
		}
	}
	return $best_stat
}

################################################################################
sub get_ethminer_cmd {
	my $stat = shift;
	my $host = $stat->{host};
	my $port = $stat->{multialgo_switch_port};
	return "ethminer --farm-retries 0 -U -S $host:$port -O $user.`hostname`:x"
}

sub get_bminer_cmd {
	my $stat = shift;
	my $host = $stat->{host};
	my $port = $stat->{multialgo_switch_port};
	return "bminer -uri stratum+ssl://$user.`hostname`\@$host:$port -max-network-failures=0 -watchdog=false"
}

sub get_ccminer_cmd {
	my $stat = shift;
	my $algo = lc $stat->{algo};
	my $host = $stat->{host};
	my $port = $stat->{multialgo_switch_port};
	return "ccminer -r 0 -a $algo -o stratum+tcp://$host:$port -u $user.`hostname` -p x"
}

################################################################################
# find whatever coin algorithm has the highest profit
# switch to mining that algorithm with ccminer
print "Starting CJ's multi-algo miner\n";
while (1) {
	print "Starting the parent loop\n";
	if (my $best_stat = get_best_stat) {
		print Dumper($best_stat) if $debug;

		# start a new child for the best algorithm
		# uses all the data we have so far to make the decision
		my $cmd;

		my $algo = lc $best_stat->{algo};
		if ($algo eq 'ethash') {
			$cmd = get_ethminer_cmd($best_stat);
		}
		elsif ($algo eq 'equihash') {
			$cmd = get_bminer_cmd($best_stat);
		}
		elsif (grep { $_ eq $algo } @ccminer_algos) {
			$cmd = get_ccminer_cmd($best_stat);
		}

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
