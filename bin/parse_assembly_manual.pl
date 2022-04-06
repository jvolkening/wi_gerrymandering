#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

my $district = 0;
while (my $dem = <STDIN>) {

    my $rep = <STDIN>;
    my $blank = <STDIN>;
    ++$district;
    chomp $dem;
    chomp $rep;
    chomp $blank;
    die "Expected empty" if (length $blank);
    die "Expected dem number" if ($dem !~ /^\d+$/);
    die "Expected rep number" if ($rep !~ /^\d+$/);
    say join "\t",
        "state_assembly_district_$district",
        'state_assembly',
        ($rep > $dem ? 1 : 0),
        ($rep > $dem ? 0 : 1),
        $rep,
        $dem,
    ;

}
