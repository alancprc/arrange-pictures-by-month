#!/usr/bin/env perl

use 5.010.001;
use Function::Parameters;
use JSON -convert_blessed_universally;
use Image::ExifTool qw(:Public);

my $debug = 1;

sub main
{
    my @src   = qw (folder-all folder-part);
    my @files = `find @src -type f`;
    chomp @files;

    for my $file (@files) {
        say $file if $debug;
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

=pod
 FileModifyDate                   : 2019:08:13 09:21:48+08:00

 MIMEType                         : image/jpeg
 DateTimeOriginal                 : 2019:08:13 09:21:50

 MIMEType                         : video/quicktime
 CreateDate                       : 2018:10:29 13:02:01
=cut

fun getYearMonth ( $file )
{
    my $exifTool = new Image::ExifTool;
    $exifTool->Options( Unknown => 1 );
    my $info = $exifTool->ImageInfo($file);

    my $time = $info->{'FileModifyDate'};
    if ( $info->{'MIMEType'} =~ /image/i and $info->{'DateTimeOriginal'} ) {
        $time = $info->{'DateTimeOriginal'};
    } elsif ( $info->{'MIMEType'} =~ /video/i and $info->{'CreateDate'} ) {
        $time = $info->{'CreateDate'};
    } else {
    }
    my @fields = split /:/, $time;
    say "@fields[0,1]" if $debug;
    return @fields[ 0, 1 ];
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
