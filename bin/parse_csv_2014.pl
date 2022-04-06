#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

my $curr_office;
my %counts;
my @results;

say join "\t", qw/
    seat
    category
    R_win
    D_win
    R_votes
    D_votes
/;
    

my $row = 0;
while (my $line = <STDIN>) {
    ++$row; 
    chomp $line;
    my @fields = split "\t", $line;

    my $tag = $fields[1];
    if (defined $tag && $tag eq 'Office') {
        parse_current($row) if (defined $curr_office);
        $curr_office = $fields[3];
        %counts = ();
        next;
    }
    next if (! defined $curr_office);
    my $party = $fields[11];
    next if (! length $party);
    my $votes = $fields[5];
    $votes =~ s/,//g;
    die "Invalid vote count ($votes) at row $row\n"
        if ($votes !~ /^\d+$/);
    $counts{$party} = $votes;
        
}
parse_current($row);

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
            
