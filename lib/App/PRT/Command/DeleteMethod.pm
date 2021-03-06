package App::PRT::Command::DeleteMethod;
use strict;
use warnings;
use PPI;

sub new {
    my ($class) = @_;
    bless {}, $class;
}

sub handle_files { 1 }

# parse arguments from CLI
# arguments:
#   @arguments
# returns:
#   @rest_arguments
sub parse_arguments {
    my ($self, @arguments) = @_;

    die "class and method required" unless @arguments >= 2;

    $self->register(shift @arguments => shift @arguments);

    @arguments;
}

# register a replacing rule
# arguments:
#   $target_class_name:  Target Class Name
#   $target_method_name: Target Method Name
sub register {
    my ($self, $target_class_name, $target_method_name) = @_;

    $self->{target_class_name} = $target_class_name;
    $self->{target_method_name} = $target_method_name;
}

sub target_class_name {
    my ($self) = @_;

    $self->{target_class_name};
}

sub target_method_name {
    my ($self) = @_;

    $self->{target_method_name};
}

sub deleted_code {
    my ($self) = @_;

    $self->{deleted_code};
}

# refactor a file
# argumensts:
#   $file: filename for refactoring
sub execute {
    my ($self, $file) = @_;

    my $document = PPI::Document->new($file);

    return unless $document;

    my $package = $document->find_first('PPI::Statement::Package');

    return unless $package;
    return unless $package->namespace eq $self->target_class_name;

    my $subs = $document->find('PPI::Statement::Sub');

    my $replaced = 0;
    for my $sub (@$subs) {
        next unless $sub->name eq $self->target_method_name;
        my @garbages;

        # comment before method
        my $cursor = $sub->first_token->previous_token;
        while (defined $cursor && ref $cursor eq 'PPI::Token::Comment') {
            unshift @garbages, $cursor;
            $cursor = $cursor->previous_token;
        }

        # method body
        push @garbages, $sub;

        # whitespace after method
        $cursor = $sub->last_token->next_token;
        while (defined $cursor && ref $cursor eq 'PPI::Token::Whitespace') {
            push @garbages, $cursor;
            $cursor = $cursor->next_token;
        }

        $self->{deleted_code} = join '', @garbages;

        $_->remove for @garbages;
        $replaced++;
    }

    $document->save($file) if $replaced;
}

1;
