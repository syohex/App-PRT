package App::PRT::Command::MoveClassMethod;
use strict;
use warnings;
use PPI;
use Path::Class;
use App::PRT::Command::ReplaceToken;
use App::PRT::Command::AddUse;

sub new {
    my ($class) = @_;
    bless {
        source_class_name       => undef,
        source_method_name      => undef,
        destination_class_name  => undef,
        destination_method_name => undef,
    };
}

sub handle_files { 1 }

# parse arguments from CLI
# arguments:
#   @arguments
# returns:
#   @rest_arguments
sub parse_arguments {
    my ($self, @arguments) = @_;

    die "source and destination are required" unless @arguments >= 2;

    $self->register(shift @arguments => shift @arguments);

    @arguments;
}


# register a replacing rule
# arguments:
#   $source: source class name and method name, joined by '#'
#   $dest:   destination class name and method name, joined by '#'
sub register {
    my ($self, $source, $destination) = @_;

    die 'invalid format' unless $source =~ qr/\A[^#]+#[^#]+\Z/;
    die 'invalid format' unless $destination =~ qr/\A[^#]+#[^#]+\Z/;

    ($self->{source_class_name}, $self->{source_method_name}) = split '#', $source;
    ($self->{destination_class_name}, $self->{destination_method_name}) = split '#', $destination;
}

sub source_class_name {
    my ($self) = @_;

    $self->{source_class_name};
}

sub source_method_name {
    my ($self) = @_;

    $self->{source_method_name};
}

sub destination_class_name {
    my ($self) = @_;

    $self->{destination_class_name};
}

sub destination_method_name {
    my ($self) = @_;

    $self->{destination_method_name};
}

# refactor a file
# argumensts:
#   $file: filename for refactoring
sub execute {
    my ($self, $file) = @_;

    $self->_try_replace_tokens($file);

    # TODO:
    # - move definition of method
    # - decide destination class location
    # - When destination class is not exists
    # - move test case?
    # - replace $class->$source_method_name to $destination_class_name->$destination_method_name

    my $replaced = 0;

    my $document = PPI::Document->new($file);

    # When parse failed
    return unless $document;

    return unless $replaced;
    $document->save($file);
}

sub _try_replace_tokens {
    my ($self, $file) = @_;

    my $command = App::PRT::Command::ReplaceToken->new;
    $command->register(
        "@{[ $self->source_class_name ]}->@{[ $self->source_method_name ]}",
        "@{[ $self->destination_class_name ]}->@{[ $self->destination_method_name ]}"
    );
    if ($command->execute($file)) {
        $self->_try_add_use($file);
    }
}

sub _try_add_use {
    my ($self, $file) = @_;

    my $command = App::PRT::Command::AddUse->new;
    $command->register($self->destination_class_name);
    $command->execute($file);
}

1;
