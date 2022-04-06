#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

my %ranges = (
    US_house       => [ 250_000, 500_000 ],
    state_assembly => [   8_000,  50_000 ],
    state_senate   => [  25_000, 120_000 ],
);

my $h = <STDIN>;
die "missing proper header\n"
    if ($h !~ /^seat\t/);

my $ln = 0;
while (my $line = <STDIN>) {
    ++$ln;

    chomp $line;
    my (
        $seat,
        $cat,
        $r_win,
        $d_win,
        $r_votes,
        $d_votes,
    ) = split "\t", $line;
    die "Bad seat name ($seat)"
        if ($seat !~ /^\w+_district_\d+$/);
    my $limits = $ranges{$cat}
        // die "Bad category ($cat)";
    die "Bad value for R_win ($r_win)"
        if ($r_win !~ /^[01]$/);
    die "Bad value for D_win ($d_win)"
        if ($d_win !~ /^[01]$/);
    die "Can't both win"
        if ($r_win == 1 && $d_win == 1);
    die "Bad value for R_votes ($r_votes)"
        if ($r_votes !~ /^\d+$/);
    die "Bad value for D_votes ($d_votes)"
        if ($d_votes !~ /^\d+$/);
    die "Win/vote inconsistency ($r_win $d_win $r_votes $d_votes)"
        if ($r_win && $r_votes < $d_votes);
    my $total = $r_votes + $d_votes;
    warn "Total ($total) too low at line $ln\n"
        if ($total < $limits->[0]);
    warn "Total ($total) too high at line $ln\n"
        if ($total > $limits->[1]);
}

