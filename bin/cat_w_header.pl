#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

for my $fn (@ARGV) {
    open my $in, '<', $fn;
    my $h = <$in>;
    while (my $line = <$in>) {
        print $line;
    }
}
