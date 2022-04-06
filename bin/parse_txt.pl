#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

my $curr_office;
my $record_start;
my @parties;
my %counts;
my @results;

my %party_map = (
    REP => 'Republican',
    DEM => 'Democrat',
);

say join "\t", qw/
    seat
    category
    R_win
    D_win
    R_votes
    D_votes
/;

for my $fn (@ARGV) {

    say STDERR $fn;
    $curr_office = undef;
    $record_start = undef;
    @parties = ();
    %counts = ();

    open my $in, '<', $fn;

    my $row = 0;
    while (my $line = <$in>) {
        ++$row; 
        chomp $line;
        if ($line =~ /^\s?Run:/) {

            parse_current($row) if (defined $curr_office);
            $record_start = $row;
            $curr_office = undef;
            @parties = ();
            %counts = ();
            next;
        }

        # extract race
        if ($row == $record_start + 4) {
            $curr_office = $line;
            next;
        }

        # extract parties
        if ($row == $record_start + 5) {
            @parties = split ' ', $line;
            next;
        }
        # extract parties
        if ($row > $record_start + 5 && $line =~ /^\s*Office Totals :\s*(.+)$/) {
            my $vote_str = $1;
            $vote_str =~ s/,//g;
            my @votes = split ' ', $vote_str;
            shift @votes; # remove total

            my @parties = map {defined $_ ? $party_map{$_} : undef} @parties;
            for (0..$#parties) {
                next if (! defined $parties[$_]);
                $counts{$parties[$_]} += $votes[$_];
            }

        }
            
    }

    parse_current($row);
    close $in;

}

for my $result ( sort {
    $a->[0] cmp $b->[0]
 || $a->[1] <=> $b->[1]
} @results) {
    say join "\t", @{ $result->[2] };
}

sub parse_current {

    my ($row) = @_;
    if (! scalar keys %counts) {
        warn "No votes found for $row, skipping\n";
        return;
    }
    my @sorted = sort {$counts{$b} <=> $counts{$a}} keys %counts;
    my $winning_party = $sorted[0];
    my $category =
          $curr_office =~ /^US Congress, District No\. \d+$/    ? 'US_house'
        : $curr_office =~ /^State Senate, District No\. \d+$/   ? 'state_senate'
        : $curr_office =~ /^State Assembly, District No\. \d+$/ ? 'state_assembly'
        : undef; 
    if (defined $category) {
        my ($district) = ($curr_office =~ /^.+ (\d+)$/);
        my $seat = join('_', $category, 'district', $district);
        push @results, [
            $category,
            $district,
            [
                $seat,
                $category,
                ($sorted[0] eq 'Republican' ? 1 : 0),
                ($sorted[0] eq 'Democrat'   ? 1 : 0),
                ($counts{'Republican'} // 0),
                ($counts{'Democrat'} // 0),
            ],
        ];
    }

}
            
