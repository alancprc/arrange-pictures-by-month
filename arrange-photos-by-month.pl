#!/usr/bin/env perl

use 5.010.001;

my @src = qw (folder-all folder-part);

my @files = `find $src`;
chomp @files;

=pod
 -rwxrwxr-x 1 aliang 100 385490 201908 sample.jpg
=cut

sub main
{
    for my $file (@files) {
        my $dst = &getYearMonth($file);
        &copyToFolder( $file, $dst );
    }
}

sub getTargetDirectory
{
    my $file = shift;

    my ( $year, $month ) = &getYearMonth($file);

    return "$year-$month";
}

# get modify date by ls -l, set $year, $month
# for .jpg .JPG .JEPG .jepg .heic .mov .MOV, get $year, $month by exiftool
sub getYearMonth
{
}

# if target_dir/$file exists and differ from $file
# do not move, keep $file where it is.
# else, move file to target_dir
sub copyToFolder
{
    my $file = shift;
    my $dst  = shift;

    if ( -e "$dst/$file" and isDiff( $file, "$dst/$file" ) ) {
        return;
    }

    system("mv $file $dst");
}

sub isDiff
{
    my $first  = shift;
    my $second = shift;
    return `diff $first $second`;
}

&main();
