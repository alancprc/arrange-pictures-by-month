#!/usr/bin/env perl

use 5.010.001;
use Function::Parameters;
use JSON -convert_blessed_universally;
use Image::ExifTool qw(:Public);

my $debug = 1;

=pod
 fun testImageExifTool ( $file ) {
     my $info = ImageInfo( $file );
     say $info;
     say to_json($info, { pretty => 1 } );
     
 }
=cut

sub main
{
    my @src   = qw (folder-all folder-part);
    my @files = `find @src -type f`;
    chomp @files;

    for my $file (@files) {
        say $file if $debug;

        # testImageExifTool( $file );
        my $dst = &getTargetDirectory($file);
        &copyToFolder( $file, $dst );
    }
}

fun getTargetDirectory ( $file )
{
    my ( $year, $month ) = &getYearMonth($file);
    return "$year-$month";
}

# TODO get year, month with exiftool
# get modify date by ls -l, set $year, $month
# for .jpg .JPG .JEPG .jepg .heic .mov .MOV, get $year, $month by exiftool
fun getYearMonth ( $file )
{
    my $result = `ls -l --time-style=+%Y-%m $file`;
    my @fields = split /\s+/, $result;
    my $time   = $fields[5];
    return split /-/, $time;
}

# if target_dir/$file exists and differ from $file
# do not move, keep $file where it is.
# else, move file to target_dir
fun copyToFolder ( $file, $dst )
{
    system("mkdir $dst") unless -e $dst;

    if ( -e "$dst/$file" and isDiff( $file, "$dst/$file" ) ) {
        return;
    } else {
        system("cp $file $dst");
    }
}

fun isDiff ( $first, $second )
{
    return `diff -q $first $second`;
}

&main();
