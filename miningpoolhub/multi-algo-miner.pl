#!/usr/bin/perl -s
# Mines using multi-algo switching on MiningPoolHub
use strict;
use warnings;

use JSON;
use Data::Dumper;

use vars qw( $debug $user $dump );
$debug = 0 unless $debug;
die "Need user" unless $user;

# get available algorithms from ccminer
my %ccminer_algos = split /\n| => /,
	`ccminer -h | awk '\$1 == "-d," {exit} p {print \$1,"=>",\$2 } \$1 == "-a," {p++}'`;
print Dumper(\%ccminer_algos) if $debug > 1;

################################################################################
# subs
################################################################################
sub get_stats {
	from_json(`curl -s "http://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics"`)
}

################################################################################
sub normalize_algo {
	my $algo = shift;

	if ($algo eq 'lyra2re2') {
		$algo = 'lyra2v2';
	}
	elsif ($algo eq 'myriad-groestl') {
		$algo = 'myr-gr';
	}

	return $algo
}

sub get_miner_to_algo {
	my ($host, $port, $algo) = @_;

	if ($algo eq 'ethash') {
		# disabled because it won't exist even after failover
		#$cmd = get_ethminer_cmd($host, $port);
	}
	elsif ($algo eq 'equihash') {
		return get_bminer_cmd($host, $port);
	}
	elsif (grep { $_ eq $algo } keys %ccminer_algos) {
		return get_ccminer_cmd($host, $port, $algo);
	}

	return
}

sub get_work {
	my $stats = get_stats;

	for my $stat (@{$stats->{return}}) {
		my $algo = normalize_algo(lc($stat->{algo}));
		my $host = $stat->{host};
		my $port = $stat->{multialgo_switch_port};
		$stat->{normalized_algo} = $algo;
		$stat->{cmd} = get_miner_to_algo($host, $port, $algo);
	}

	return $stats->{return}
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

# dump prints a script
if (defined $dump) {
	open FILE, '>', $dump or die $!;

	printf FILE "#!%s", `which bash`;
	printf FILE "# generated on %s", `date`;
	print FILE "while true\n";
	print FILE "do\n";
	for my $work (@{get_work()}) {
		if (my $cmd = $work->{cmd}) {
			print FILE "\t$cmd\n"
		}
	}
	print FILE "\tsleep 3\n";
	print FILE "done\n";
	close FILE;
	exit
}

print "Starting CJ's multi-algo miner\n";
while (1) {
	print "Starting the parent loop\n";

	for my $work (@{get_work()}) {
		print "Workload: ",Dumper($work) if $debug > 1;
		if (my $cmd = $work->{cmd}) {
			print "Starting child: $cmd\n";
			system $cmd unless $debug
		}
		else {
			print join(', ', keys %ccminer_algos), "\n" if $debug > 1;
			printf "Nothing can run this algorithm: %s\n", $work->{algo};
		}
	}
	exit if $debug;
	sleep 3
}
