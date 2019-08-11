#!/usr/bin/perl

use strict;
use warnings;
use Crypt::Eksblowfish::Bcrypt qw/bcrypt/;
use Crypt::OpenSSL::Random;
use Digest::SHA;
use Time::Piece qw//;
use Time::Piece::MySQL;

my $BASE_PRICE = 108;
my $NUM_USER_GENERATE = 200;
my $NUM_ITEM_GENERATE = 10000;
my $RATE_OF_SOLDOUT = 30;

my $PASSWORD_SALT = 'Oi87WbXmCRnFZATUm4fXUJUE8VLdiI4tGk17M1K3SmS';
my @ADDTIONAL_ADDREDSS = qw/
青葉区
泉区
太白区
宮城野区
若林区
東区
白石区
厚別区
豊平区
清田区
南区
西区
手稲区
秋葉区
江南区
西蒲区
川崎区
幸区
中原区
高津区
宮前区
多摩区
麻生区
旭区
磯子区
神奈川区
金沢区
港南区
栄区
瀬谷区
都筑区
鶴見区
戸塚区
保土ケ谷区
緑区
伊洲根区
清水区
葵区
駿河区
浜北区
天竜区
熱田区
昭和区
千種区
天白区
中川区
中村区
瑞穂区
名東区
守山区
左京区
上京区
右京区
中京区
東山区
山科区
伏見区
西京区
下京区
中京区
大宮区
見沼区
桜区
浦和区
岩槻区
/;
my @CATEGOREIS_WEIGHT = (
[[2,1],1],
[[3,1],2],
[[4,1],1],
[[5,1],1],
[[6,1],1],
[[11,10],3],
[[12,10],2],
[[13,10],2],
[[14,10],3],
[[15,10],1],
[[21,20],3],
[[22,20],5],
[[23,20],3],
[[24,20],2],
[[31,30],4],
[[32,30],3],
[[33,30],2],
[[34,30],1],
[[35,30],1],
[[41,40],4],
[[42,40],2],
[[43,40],2],
[[44,40],2],
[[45,40],2],
[[51,50],1],
[[52,50],2],
[[53,50],1],
[[54,50],2],
[[55,50],1],
[[56,50],1],
[[61,60],3],
[[62,60],2],
[[63,60],1],
[[64,60],3],
[[65,60],3],
[[66,60],4]
);
my @CATEGOREIS=();
for my $cw (@CATEGOREIS_WEIGHT) {
    for (my $i=0;$i<$cw->[1];$i++) {
        push @CATEGOREIS, $cw->[0];
    }
}

sub encrypt_password {
    my $password = shift;
    my $salt = shift || Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::OpenSSL::Random::random_bytes(16));
    my $settings = '$2a$10$'.$salt;
    return Crypt::Eksblowfish::Bcrypt::bcrypt($password, $settings);
}

# Check if the passwords match
sub check_password {
    my ($plain_password, $hashed_password) = @_;
    if ($hashed_password =~ m!^\$2a\$\d{2}\$([A-Za-z0-9+\\.]{22})!) {
        return encrypt_password($plain_password, $1) eq $hashed_password;
    } else {
        return;
    }
}

my %users = ();
{
    open(my $fh, "<", "users.tsv") or die $!;
    my @dummy_users = map { chomp $_; [ split /\t/, $_, 3] } <$fh>;
    my $format = q!INSERT INTO `users` (`id`,`account_name`,`hashed_password`,`address`,`created_at`) VALUES (%d,'%s','%s','%s','%s');!."\n";
    # For demo
    printf($format, 1, 'isudemo1', encrypt_password('isudemo1'), '東京都港区6-11-1', '2019-09-06 00:00:00');
    $users{1} = ['isudemo1','東京都港区6-11-1'];
    printf($format, 2, 'isudemo2', encrypt_password('isudemo2'), '東京都新宿区4-1-6', '2019-09-06 00:00:01');
    $users{2} = ['isudemo2','東京都新宿区4-1-6'];
    printf($format, 3, 'isudemo3', encrypt_password('isudemo3'), '東京都伊洲根9-4000', '2019-09-06 00:00:02');
    $users{3} = ['isudemo3','東京都伊洲根9-4000'];
    my $base_time = 1567695603; #2019-09-06 00:00:03
    srand(1565458009);
    for (my $i=4;$i<=$NUM_USER_GENERATE;$i++) {
        my $dummy_user = $dummy_users[$i];
        my $id = $dummy_user->[1];
        $id =~ s/@.+$//g;
        my $ad1 = int(rand(5))+1;
        my $ad2 = int(rand(50))+1;
        my $address = $dummy_user->[2] . $ADDTIONAL_ADDREDSS[$i % (scalar @ADDTIONAL_ADDREDSS)] . $ad1 . "-" . $ad2;
        $users{$i} = [$id,$address];
        printf(
            $format,
            $i,
            $id,
            encrypt_password(Digest::SHA::hmac_sha256_base64($id,$PASSWORD_SALT)),
            $address,
            Time::Piece::localtime($base_time+$i)->mysql_datetime,
        );
    }
}

open(my $fh, "<", "keywords.txt") or die $!;
my @KEYWORDS = map { chomp $_; $_ } <$fh>;

sub gen_text {
    my ($length, $return) = @_;
    my @text;
    for (my $i=0;$i<$length;$i++) {
        my $r = int(rand(scalar @KEYWORDS));
        my $t = $KEYWORDS[$r];
        chomp($t);
        if ($t eq "#") {
            $t = "\n" if $return;
            $t = " " if !$return;
        }
        push @text, $t;
    }
    my $text = join "", @text;
    $text =~ s/^(\s|\n)+//gs;
    return $text;
}

{
    my $base_time = 1567702867; #2019-09-06 02:01:07
    srand(1565358009);
    my $items_format = q!INSERT INTO `items` (`id`,`seller_id`,`buyer_id`,`status`,`name`,`price`,`description`,`category_id`,`created_at`,`updated_at`) VALUES (%d, %d, %d, '%s', '%s', %d, '%s', %d, '%s', '%s');!."\n";

    my $te_format = q!INSERT INTO `transaction_evidences` (`id`,`seller_id`,`buyer_id`,`status`,`item_id`,`item_name`,`item_price`,`item_description`,`item_category_id`,`item_root_category_id`,`created_at`,`updated_at`) VALUES (%d, %d, %d, '%s', %d, '%s', %d, '%s', %d, %d, '%s', '%s');!."\n";

    my $shippings_format = q!INSERT INTO `shippings` (`transaction_evidence_id`,`status`,`item_name`,`item_id`,`reserve_id`,`reserve_time`,`to_address`,`to_name`,`from_address`,`from_name`,`img_binary`,`created_at`,`updated_at`) VALUES (%d, '%s', '%s', %d, '%s', %d, '%s', '%s', '%s', '%s', '%s', '%s', '%s');!."\n";


    my $te_id = 0;
    for (my $i=1;$i<=$NUM_ITEM_GENERATE;$i++) {
        my $t_sell = Time::Piece::localtime($base_time+rand(10)-5);
        my $t_buy = $t_sell + rand(10) + 60;
        my $t_done = $t_buy + 10;

        my $n = gen_text(8,0),;
        $n =~ s/\s+/ /g;
        my $d = gen_text(200,1);
        $d =~ s/\n/\\n/g;

        my $seller = int(rand($NUM_USER_GENERATE))+1;
        my $status = 'on_sale';
        my $buyer = 0;

        my $category = $CATEGOREIS[int(rand(scalar @CATEGOREIS))];

        if (rand(100) < $RATE_OF_SOLDOUT) {
            $status = 'sold_out';
            $te_id++;
            $buyer = int(rand($NUM_USER_GENERATE))+1;
            while ($buyer == $seller) {
                $buyer = int(rand($NUM_USER_GENERATE))+1;
            }

            printf(
                $te_format,
                $te_id,
                $seller,
                $buyer,
                'done',
                $i,
                $n,
                $BASE_PRICE,
                $d,
                $category->[0],
                $category->[1],
                $t_buy->mysql_datetime,
                $t_done->mysql_datetime
            );

            printf(
                $shippings_format,
                $te_id,
                'done',
                $n,
                $i,
                "0000000000", # XXX reserve_id
                $t_buy->epoch,
                $users{$buyer}->[1],
                $users{$buyer}->[0],
                $users{$seller}->[1],
                $users{$seller}->[0],
                "", # XXX img_binary
                $t_buy->mysql_datetime,
                $t_done->mysql_datetime
            );
        }

        printf(
            $items_format,
            $i,
            $seller,
            $buyer, # buyer
            $status,
            $n,
            $BASE_PRICE,
            $d,
            $category->[0],
            $t_sell->mysql_datetime,
            $t_done->mysql_datetime
        );
        $base_time++;
    }
}
