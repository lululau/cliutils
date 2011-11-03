#!/usr/bin/perl

use strict;
use Encode qw/encode decode/;

print STDERR "\033[31mInput file must be utf8 encoded if contains non-ascii chars.\033[0m\n";

my $column_num = $ARGV[0];

my @lines = ();

while (my $line = <STDIN> ) {
  my @fields = map {"" . encode("gbk", decode("utf8", $_))} (split /\s+/, $line);  
  if (@fields != $column_num) {
    print STDERR "Line $. contains " . (0+@fields) . " fields.\n";
    exit 1;
  }
  push @lines, [@fields];
}

my @max_length = ();
for my $i (1 .. $column_num) {
  my $max = 0;
  for (@lines) {
    my $len = length $_->[$i - 1];
    $max = $len if $len > $max;
  }
  push @max_length, $max;
}

for (@max_length) {
  print "+" . "-" x ($_ + 2);
}
print "+\n";

for my $i(1 .. $column_num) {
  my $field = $lines[0]->[$i - 1];
  my $length = length $field;  
  my $field = encode("utf8", decode("gbk", $field));
  print "| " . $field . " " x ($max_length[$i - 1] - $length + 1);
}
print "|\n";

for (@max_length) {
  print "+" . "-" x ($_ + 2);
}
print "+\n";


for my $i(2 .. @lines) {
  my $fields = $lines[$i - 1];
  for my $j(1 .. $column_num) {
    my $field = $fields->[$j - 1];
    my $length = length $field;  
    my $field = encode("utf8", decode("gbk", $field));
    print "| " . $field . " " x ($max_length[$j - 1] - $length + 1);
  }
  print "|\n";
}

for (@max_length) {
  print "+" . "-" x ($_ + 2);
}
print "+\n";
