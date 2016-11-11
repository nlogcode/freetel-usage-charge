#!/usr/bin/perl
use strict;
use Web::Scraper;
use WWW::Mechanize;
use Number::Format qw(:subs);
use DateTime;

my $userid = 'UserID for freetel.jp';
my $passwd = 'Password for freetel.jp';
my $event = 'IFTTT event name';
my $secret_key = 'IFTTT secret key';

my $dt = DateTime->now(time_zone => 'local');

my $mech = WWW::Mechanize->new();
$mech->get('https://mypage.freetel.jp/login') or die;
$mech->submit_form(
    fields => {
        'data[SimUser][userDesignationId]' => $userid,
        'data[SimUser][password]' => $passwd,
    }
);

my $scraper1 = scraper {
    process 'h2', 'phone[]' => 'TEXT';
    process 'dl > dt > span', 'usage[]' => 'TEXT';
};
my $scraper2 = scraper {
    process 'div > div.col-xs-6.col-sm-3.align-right > span:nth-child(1)', 'charge[]' => 'TEXT';
};
$mech->get('https://mypage.freetel.jp/SavingMode') or die;
my $result1 = $scraper1->scrape($mech->content);
$mech->get('https://mypage.freetel.jp/Specification/thisMonth/' . $dt->strftime('%Y%m')) or die;
my $result2 = $scraper2->scrape($mech->content);

for (my $i = 0; $i <= $#{$result1->{phone}}; $i++) {
    ${$result1->{usage}}[$i * 2] =~ /(\S+)B/;
    my $usage = int(unformat_number($1, base => 1024));
    my $charge = defined(${$result2->{charge}}[$i]) ? unformat_number(${$result2->{charge}}[$i]) : 0;
    print $$, ":", $dt->strftime('%Y%m%d:%H%M%S.%3N'), "\t", ${$result1->{phone}}[$i], "\t", $usage, "\t", $charge, "\n";
    $mech->get("http://maker.ifttt.com/trigger/" . $event . "/with/key/" . $secret_key . "?value1=" . ${$result1->{phone}}[$i] . "&value2=" . $usage . "&value3=" . $charge) if ($event ne '') or die;
}
