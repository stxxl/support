#!/usr/bin/perl -w

use strict;
use warnings;

sub readlog($) {
    my ($tag) = @_;

    my $log = `git log -z '--pretty=format:%H %B' $tag`;

    my %rev;

    print STDERR "Revision <-> Hash map of tag $tag\n";

    foreach my $commit (split/\0/,$log)
    {
        unless ($commit =~ /^([0-9a-f]{40}) (.+)$/s) {
            die $commit;
        }
        my ($hash,$msg) = ($1,$2);
        if ($msg =~ /@([0-9]{1,4}) /) {
            #print "rev: $1 = $hash\n";
            $rev{$1} = $hash;
            $rev{$hash} = $1;
        }
    }

    return %rev;
}

# read svn -> githash map for master and master-new branches
my %revnew = readlog("master-new");
my %revold = readlog("master");

sub outputmap {
    my ($tag) = @_;

    my $log = `git log -z '--pretty=format:%H %P' $tag`;

    foreach my $commit (split/\0/,$log)
    {
        my @hash = split(/ /, $commit);

        my $base = shift(@hash);
        next if $revold{$base};

        my @out;

        foreach (@hash)
        {
            my $h = $_;
            if ($revold{$h})
            {
                my $hnew = $revnew{$revold{$h}};
                #print STDERR "Mapping $h -> $hnew\n";
                $h = $hnew;
            }
            push(@out, $h);
        }

        if (!(@hash ~~ @out)) {
            print $base." ".join(" ", @out)."\n";
            #print $base." ".join(" ", @hash)."\n";
        }
    }
}

foreach my $arg (@ARGV) {
    outputmap($arg);
}
