# ABSTRACT: schedule a downtime for a host/service

package App::I2::API::Command::down;

use strict;
use warnings;
use experimental qw( signatures );

use Carp;

use App::I2::API -command;
use App::I2::API::Misc;
use JSON::XS;
use Time::Piece;

sub usage_desc {
    return "$0 down -a [--host] HOSTNAME -s [--service] SERVICE --start YYYY-MM-DD HH:MM:SS -t [--time] TIME -c [--comment] COMMENT [--remove]";
}

sub description {
    return "Schedule downtime via Icinga2 API";
}

sub opt_spec {
    return (
        [ 'host|a=s',    'Server hostname' ],
        [ 'service|s=s', 'List of services' ],
        [ 'start=s',     'Start time' ],
        [ 'time|t=i',    'Amount of time (in minutes)' ],
        [ 'comment|c=s', 'Comment' ],
        [ 'remove',      'Remove downtime' ],
    );
}

sub validate_args ( $self, $opt, $args ) {
    croak 'Host is missing!'
      if !$opt->{host};
    croak 'Time is missing!'
      if ( !$opt->{time} && !$opt->{remove} );
    croak 'Comment is missing!'
      if ( !$opt->{comment} && !$opt->{remove} );
    if ( $opt->{start} && $opt->{start} !~ /^[0-9]{4}-[0-1]{1}[0-9]{1}-[0-3]{1}[0-9]{1}\s[0-1]{1}[0-9]{1}:[0-5]{1}[0-9]{1}:[0-5]{1}[0-9]{1}$/) {
        croak 'Start time is in incorrect format!'
    } 
    return;
}

sub execute ( $self, $opt, $args ) {
    my $new_url = $icinga_url . "schedule-downtime";
    my $data;
    my %hash = (
        type    => 'Service',
    );
    if ( !$opt->{remove} ) {
        my $cur_time;
        if ( !$opt->{start} ) {
            $cur_time = localtime(time)->epoch;
        }
        else {
            my $tz = localtime(time)->strftime('%z');
            $cur_time = Time::Piece->strptime( "$opt->{start} $tz" , "%Y-%m-%d %H:%M:%S %z")->epoch;
        }
        my $end_time = $opt->{time} * 60 + $cur_time;
        $hash{"author"} = $icinga_user;
        $hash{"comment"} = $opt->{comment};
        $hash{"start_time"} = $cur_time;
        $hash{"end_time"} = $end_time;
    }
    else {
        $new_url = $icinga_url . "remove-downtime";
    };
    if ( !$opt->{service} ) {
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
            $data = encode_json(\%hash);
            send_query( $new_url, $data, $opt );
        }
    }
}

1;
