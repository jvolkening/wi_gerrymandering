#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

my %party_map = (
    REP => 'Republican',
    DEM => 'Democrat'
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
my %counts;
my @results;

for my $fn (@ARGV) {

    $curr_office = undef;
    %counts = ();
    my @parties;

    open my $in, '<', $fn;
    my $ln = 0;
    while (my $line = <$in>) {
        ++$ln;
        chomp $line;
        my @fields = split ',', $line;

        if ($ln == 5) {
            $curr_office = $fields[0];
        }
        if ($ln == 7) {
            @parties = @fields[3..$#fields];
        }
        if ($ln > 7 && $fields[0] eq 'Office Totals:') {
            my @votes = @fields[3..$#fields];
            @parties = map {$party_map{$_}} @parties;
            for (0..$#parties) {
                next if (! defined $parties[$_]);
                $counts{$parties[$_]} += $votes[$_];
            }
        }
            
    }

    parse_current($fn);

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
        warn "No votes found for $row\n";
        return;
    }
    my @sorted = sort {$counts{$b} <=> $counts{$a}} keys %counts;
    my $winning_party = $sorted[0];
    my $category =
          $curr_office =~ /^CONGRESSIONAL - DISTRICT \d+$/     ? 'US_house'
        : $curr_office =~ /^STATE SENATE - DISTRICT \d+$/                  ? 'state_senate'
        : $curr_office =~ /^ASSEMBLY - DISTRICT \d+$/ ? 'state_assembly'
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
            
