#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;

use DateTime::Format::Excel;
use Getopt::Long;
use Try::Tiny;

my $fi_xlsx;
my $fo_table;
my $fo_id_list;
my $n_header_rows = 1;
my $library_id_col;
my @description_item_col;
my @method_item_col;
my $molecule_type;
my $host_col;
my $host_id = 'NA';
my $sub_underscores = 0;

my $curr_office;
my %counts;

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
    my $party = $fields[10];
    next if (! length $party);
    my $votes = $fields[4];
    $votes =~ s/,//g;
    die "Invalid vote count ($votes) at row $row\n"
        if ($votes !~ /^\d+$/);
    $counts{$party} = $votes;
        
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
        say join "\t",
            $curr_office,
            $category,
            ($sorted[0] eq 'Republican' ? 1 : 0),
            ($sorted[0] eq 'Democrat'   ? 1 : 0),
            ($counts{'Republican'} // 0),
            ($counts{'Democrat'} // 0),
        ;
    }

}
            
