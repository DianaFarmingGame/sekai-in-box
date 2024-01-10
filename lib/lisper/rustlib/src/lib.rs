#![feature(let_chains)]
use godot::prelude::*;

mod parser;

struct GispExtension;

#[gdextension]
unsafe impl ExtensionLibrary for GispExtension {}

use crate::parser::GispParser;

#[derive(GodotClass)]
#[class(init, rename=GispParser)]
struct GdGispParser { raw: GispParser }

#[godot_api]
impl GdGispParser {
    #[func]
    pub fn make(source: GString) -> Gd<GdGispParser> {
        Gd::from_object(GdGispParser { raw: GispParser::make(source) })
    }

    #[func]
    fn duplicate(&self) -> Gd<GdGispParser> {
        Gd::from_object(GdGispParser { raw: self.raw.clone() })
    }

    #[func]
    fn parse(&mut self) -> bool {
        self.raw.r_root()
    }

    #[func]
    fn get_result(&self) -> VariantArray {
        self.raw.get_result()
    }
}