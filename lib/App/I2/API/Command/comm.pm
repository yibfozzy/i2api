# ABSTRACT: leave comment for a host/service

package App::I2::API::Command::comm;

use strict;
use warnings;
use experimental qw( signatures );

use Carp;

use App::I2::API -command;
use App::I2::API::Misc;
use JSON::XS;

sub usage_desc {
    return "$0 comm -a [--host] HOSTNAME -s [--service] SERVICE -c [--comment] COMMENT [--remove]";
}

sub description {
    return "Leave a comment via Icinga2 API";
}

sub opt_spec {
    return (
        [ 'host|a=s',    'Server hostname' ],
        [ 'service|s=s', 'List of services' ],
        [ 'comment|c=s', 'Comment' ],
        [ 'remove',      'Remove comment' ],
        [ 'hostonly',    'Leave comment only for host' ],
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
    my $new_url = $icinga_url . 'add-comment';
    my %hash;
    if ( !$opt->{remove} ) {
        $hash{"author"} = $icinga_user;
        $hash{"comment"} = $opt->{comment};
    }
    else {
        $new_url = $icinga_url . 'remove-comment';
    }
    if ( !$opt->{service} ) {
        my $data;
        $hash{"filter"} = 'host.name=="' . $opt->{host} . '"';
        $hash{"type"} = 'Host';
        $data = encode_json(\%hash);
        send_query( $new_url, $data, $opt );
        if ( !$opt->{hostonly} ) {
            $hash{"type"} = 'Service';
            $data = encode_json(\%hash);
            send_query( $new_url, $data, $opt );
        }
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
