#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Spreadsheet::Read;

my %party_map = (
    Republican => 'Republican',
    Democratic => 'Democrat',
);

say join "\t", qw/
    seat
    category
    R_win
    D_win
    R_votes
    D_votes
/;

my $curr_office;
my @parties;
my %counts;
my @results;

for my $fn (@ARGV) {

    $curr_office = undef;
    @parties = ();
    %counts = ();

    my $book = Spreadsheet::Read->new($fn);
    my $sheet = $book->sheet(1);

    for my $row (1..$sheet->maxrow()) {

        # handle race header
        next if (! defined $sheet->cell(2, $row));
        if ($sheet->cell(1, $row) eq 'DATE') {

            if (defined $curr_office) {
                parse_current($row);
                $curr_office = undef;
                @parties = ();
                %counts = ();
            }

            my @row = $sheet->row($row);
            @parties = @row[17..$#row];
        }

        # get current race
        elsif ($sheet->cell(3,$row) eq 'GENERAL') {
            $curr_office //= $sheet->cell(5, $row);
            my @row = $sheet->row($row);
            my @votes = @row[17..$#row];

            my @parties = map {defined $_ ? $party_map{$_} : undef} @parties;
            for (0..$#parties) {
                next if (! defined $parties[$_]);
                $counts{$parties[$_]} += $votes[$_];
            }
        }

        # get vote totals
        elsif (defined $sheet->cell(17, $row)
              && $sheet->cell(17,$row) eq 'TOTAL') {
            my @row = $sheet->row($row);
            my @votes = @row[17..$#row];

            @parties = map {defined $_ ? $party_map{$_} : undef} @parties;
            for (0..$#parties) {
                next if (! defined $parties[$_]);
                if ($counts{$parties[$_]} != $votes[$_]) {
                    die "Vote total mismatch at $fn, $row (exp. $counts{$parties[$_]}, got $votes[$_])\n";
                }
            }
        }

    }

    parse_current('final');

}

for my $result ( sort {
    $a->[0] cmp $b->[0]
 || $a->[1] <=> $b->[1]
} @results) {
    say join "\t", @{ $result->[2] };
}

sub parse_current {

    my ($row) = @_;
    die "No votes found for $row\n"
        if (! scalar keys %counts);
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

