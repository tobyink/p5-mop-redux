use strict;
use warnings;
use mop;

role mopx::types {
	method attribute_class () { "mopx::types::attribute" }
}

class mopx::types::attribute (extends => "mop::attribute") {
	has $isa;
	method type_constraint () {
		return $isa;
	}
	method has_type_constraint () {
		return defined($isa);
	}
	method store_data_in_slot_for ($instance, $data) {
		not($self->has_type_constraint)
			or $self->type_constraint->check($data)
			or die($self->type_constraint->get_message($data));
		$self->mop::next::method($instance, $data);
	}
}

1;
