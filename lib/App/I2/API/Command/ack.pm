# ABSTRACT: acknowledge problem for a host/service

package App::I2::API::Command::ack;

use strict;
use warnings;
use experimental qw( signatures );

use Carp;

use App::I2::API -command;
use App::I2::API::Misc;
use JSON::XS;
use Time::Piece;

sub usage_desc {
    return "$0 ack -a [--host] HOSTNAME -s [--service] SERVICE -t [--time] TIME -c [--comment] COMMENT [--remove] [--notify]";
}

sub description {
    return "Acknowledge problem via Icinga2 API";
}

sub opt_spec {
    return (
        [ 'host|a=s',    'Server hostname' ],
        [ 'service|s=s', 'List of services' ],
        [ 'time|t=i',    'Amount of time (in minutes)' ],
        [ 'comment|c=s', 'Comment' ],
        [ 'remove',      'Remove acknowledgement' ],
        [ 'notify',      'Send notification' ],
        [ 'sticky',      'Set ack until host/service is fully recovered' ],
        [ 'persistent',  'Leave comment after the host recovers' ],
    );
}

sub validate_args ( $self, $opt, $args ) {
    croak 'Host is missing!'
      if ( !$opt->{host} );
    croak 'Comment is missing!'
      if ( !$opt->{comment} && !$opt->{remove} );
    return;
}

sub execute ( $self, $opt, $args ) {
    my $new_url = $icinga_url . 'acknowledge-problem';
    my %hash = (
        type    => 'Service',
    );
    $hash{"notify"} = '1' if $opt->{notify};
    $hash{"sticky"} = '1' if $opt->{sticky};
    $hash{"persistent"} = '1' if $opt->{persistent};
    if ( !$opt->{remove} ) {
        $hash{"author"} = $icinga_user;
        $hash{"comment"} = $opt->{comment};
        if ( $opt->{time} ) {
            my $cur_time = localtime(time)->epoch;
            my $end_time = $opt->{time} * 60 + $cur_time;
            $hash{"expiry"} = $end_time;
        }
    }
    else {
        $new_url = $icinga_url . 'remove-acknowledgement';
    }
    if ( !$opt->{service} ) {
        my $data;
        $hash{"filter"} = 'host.name=="' . $opt->{host} . '"';
        $data = encode_json(\%hash);
        send_query( $new_url, $data, $opt );
        $hash{"type"} = 'Host';
        $data = encode_json(\%hash);
        send_query( $new_url, $data, $opt );
    }
    else {
        for my $service ( split( /,/, $opt->{service} ) ) {
            $hash{"filter"} = 'service.name=="' . $service . '" && host.name=="' . $opt->{host} . '"';
            my $data = encode_json(\%hash);
            send_query( $new_url, $data, $opt );
        }
    }
}

1;
