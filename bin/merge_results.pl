#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use File::Basename;

my @dirs = @ARGV;

my $header_written = 0;

for my $dir (@dirs) {
    my $fn_in = "$dir/results.tsv";
    say STDERR "Missing input $fn_in"
        if (! -e $fn_in);
    my $year = basename $dir;

    open my $in, '<', $fn_in;
    my $h = <$in>;
    if (! $header_written) {
        chomp $h;
        say join "\t",
            'year',
            $h,
        ;
        $header_written = 1;
    }
    while (my $line = <$in>) {
        chomp $line;
        say join "\t",
            $year,
            $line,
        ;
    }
}
