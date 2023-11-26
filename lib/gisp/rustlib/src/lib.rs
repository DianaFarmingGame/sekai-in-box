#![feature(let_chains)]
use godot::prelude::*;

mod parser;

struct GispExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GispExtension {}
