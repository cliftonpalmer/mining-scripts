#!/usr/bin/perl -s
# Mines using multi-algo switching on MiningPoolHub
use strict;
use warnings;

use JSON;
use Data::Dumper;

################################################################################
# init
################################################################################
use constant CHILD_FILE => '/etc/multi-algo/child.json';

use vars qw( $dryrun $debug $user $token $interval );
$interval = 1 unless $interval;
$interval = int(60 * $interval);
$dryrun = 0 unless $dryrun;
$debug = 0 unless $debug;
die "Need user" unless $user;
die "Need API token" unless $token;

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

		# skip this algo if ccminer can't handle it
		next unless grep { $_ eq lc($stat->{algo}) } @ccminer_algos;

		if ($stat->{profit} > $best_stat->{profit}) {
			$best_stat = $stat;
		}
	}
	return $best_stat
}

################################################################################
sub get_ccminer_cmd {
	my $stat = shift;
	my $algo = lc $stat->{algo};
	my $host = $stat->{host};
	my $port = $stat->{multialgo_switch_port};
	return "ccminer -r 0 -a $algo -o stratum+tcp://$host:$port -u $user.`hostname` -p x"
}

################################################################################
sub get_child_info {
	if (open my $fh, '<', CHILD_FILE) {
		my $child_info = from_json(<$fh>);
		close $fh;
		return $child_info;
	}
}

################################################################################
sub set_child_info {
	my $child_info = shift;
	if (open my $fh, '>', CHILD_FILE) {
		print $fh to_json($child_info);
		close $fh;
	}
}

################################################################################
sub start_child {
	my $cmd = shift;
	my $pid;
	die "fork: $!" unless defined ($pid = fork);
	if ($pid) { # parent
		return $pid;
	}
	else { # child
		exec $cmd;
	}
}

################################################################################
sub stop_child {
	my $child_pid = shift;
	kill 'TERM', $child_pid;
	waitpid $child_pid, 0;
}

################################################################################
# logic
################################################################################

# find whatever coin algorithm has the highest profit
# switch to mining that algorithm with ccminer
while (1) {
	if (my $best_stat = get_best_stat) {
		print Dumper($best_stat) if $debug;

		# if I'm already mining the best algorithm, then exit
		# otherwise, kill the child
		if (my $child_info = get_child_info) {
			if ($child_info->{algo} eq $best_stat->{algo}) {
				print "Already mining the best algorithm, exiting\n";
				goto DONE_LOOP;
			}
			else {
				my $child_pid = $child_info->{pid};
				if ($dryrun) {
					print "Would kill child $child_pid here\n";
				}
				else {
					print "Stopping child: $child_pid\n";
					stop_child($child_pid);
				}
			}
		}

		# start a new child for the best algorithm
		# uses all the data we have so far to make the decision
		my $cmd = get_ccminer_cmd($best_stat);
		$best_stat->{cmd} = $cmd;

		if ($dryrun) {
			print "Would start child here: $cmd\n";
		}
		else {
			print "Starting child: $cmd\n";
			my $pid = start_child($cmd);
			$best_stat->{pid} = $pid;
			set_child_info($best_stat);
		}
	}
	else {
		print "Nothing to mine!\n";
	}

DONE_LOOP:
	# parent sleeps until I decide to check again
	print "Parent sleeping for $interval seconds\n";
	sleep $interval;
}
