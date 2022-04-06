#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use Text::CSV qw/csv/;

my $curr_office;
my $record_start;
my @parties;
my %counts;
my @results;

my $category = shift @ARGV;

my %party_map = (
    'Rep.' => 'Republican',
    'Dem.' => 'Democrat',
);

say join "\t", qw/
    seat
    category
    R_win
    D_win
    R_votes
    D_votes
/;

my $aoa = csv (in => $ARGV[0]);

my $row = 0;
for my $r (@{$aoa}) {
    ++$row; 
    my @fields = @{ $r };

    # validate and clean up fields
    for (0..$#fields) {
        my $f = $fields[$_];
        $f =~ s/^'//g;
        $f =~ s/\s*$//g;
        $fields[$_] = $f;
    }

    if ($fields[0] =~ /^(\d+)(?:st|nd|rd|th)$/) {
        if (defined $curr_office) {
            parse_current($row);
            $record_start = $row;
            $curr_office = undef;
            @parties = ();
            %counts = ();
         }
        $curr_office = $1;
    }
    elsif (length $fields[0]) {
        die "Invalid first field: $fields[0]";
    }
    my $party_field =
        $category eq 'state_senate'   ? 3
      : $category eq 'state_assembly' ? 1
      : die "Bad category";
    my $party = $party_map{ $fields[$party_field] };
    next if (! defined $party);
    my $vote_field =
        $category eq 'state_senate'   ? 5
      : $category eq 'state_assembly' ? 3
      : die "Bad category";
    my $votes = $fields[$vote_field];
    $votes =~ s/,//g;
    $votes =~ s/[^[:ascii:]]$//;
    die "Bad vote value on $row: $votes"
        if ($votes !~ /^\d+$/);
    $counts{$party} += $votes;

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
    if (! scalar keys %counts) {
        warn "No votes found for $row, skipping\n";
        return;
    }
    my @sorted = sort {$counts{$b} <=> $counts{$a}} keys %counts;
    my $winning_party = $sorted[0];
    my $district = $curr_office;
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
            
