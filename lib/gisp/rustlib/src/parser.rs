use std::rc::Rc;
use godot::prelude::*;
use unescape::unescape;

#[derive(Default)]
struct GispStream {
    raw: Vec<char>,
}

impl GispStream {
    pub fn make(raw: GString) -> GispStream {
        GispStream { raw: unsafe { raw.chars_unchecked().to_owned() } }
    }

    fn rpick(&self, offset: usize) -> Option<char> {
        if (offset) < self.raw.len() {
            Some(self.raw[offset])
        } else { None }
    }

    fn len(&self) -> usize {
        self.raw.len()
    }
}

enum TType {
    TOKEN,
    NUMBER,
    BOOL,
    KEYWORD,
    STRING,
    CALL,
    ARRAY,
    MAP,
}

#[derive(Clone, Default)]
pub struct GispParser {
    stream: Rc<GispStream>,
    offset: usize,
    result: Vec<Variant>,
}

impl GispParser {
    pub fn make(source: GString) -> GispParser {
        GispParser {
            stream: Rc::new(GispStream::make(source)),
            offset: 0,
            result: Vec::new(),
        }
    }

    fn rfork(&self) -> GispParser {
        GispParser {
            stream: self.stream.clone(),
            offset: self.offset,
            result: Vec::new(),
        }
    }

    fn push(&mut self, ptype: TType, data: Variant) {
        self.result.push(Array::from(&[(ptype as u32).to_variant(), data]).to_variant());
    }

    pub fn r_root(&mut self) -> bool {
        let mut np = self.rfork();
        while np.r_blank() && np.r_item() {}
        if np.offset == np.stream.len() {
            self.offset = np.offset;
            self.result = np.result;
            true
        } else {
            false
        }
    }

    fn r_blank(&mut self) -> bool {
        while self.r_whitespace() && (self.r_comment() || self.r_skiper()) {}
        true
    }

    fn r_comment(&mut self) -> bool {
        if self.rpick() == Some(';') {
            self.offset += 1;
            loop {
                if let Some(c) = self.rpick() && c != '\n' {
                    self.offset += 1;
                } else {
                    return true;
                }
            }
        }
        false
    }

    fn r_skiper(&mut self) -> bool {
        if self.rpick() == Some('#') && self.rpick_offset(1) == Some(';') {
            self.offset += 2;
            let mut np = self.rfork();
            np.r_blank();
            let _ = np.r_item() && np.r_blank() && np.r_call();
            self.offset = np.offset;
            true
        } else {
            false
        }
    }

    fn r_whitespace(&mut self) -> bool {
        while let Some(c) = self.rpick() && _CS_BLANK.contains(c) {
            self.offset += 1;
        }
        true
    }

    fn r_expresser(&mut self) -> bool {
        if self.rpick() == Some('#') && self.rpick_offset(1) == Some('(') {
            self.offset += 1;
            if self.r_expression() {
                true
            } else {
                self.offset -= 1;
                false
            }
        } else {
            false
        }
    }

    fn r_expression(&mut self) -> bool {
        if self.rpick() == Some('(') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && np.r_expr_item() {}
            np.r_blank();
            if np.rpick() == Some(')') {
                let mut body = np.result.into_iter();
                if let Some(mut tar) = body.next() {
                    loop {
                        if let Some(opt) = body.next() {
                            if let Some(src) = body.next() {
                                tar = Array::from(&[(TType::CALL as u32).to_variant(), Array::from(&[opt, tar, src]).to_variant()]).to_variant();
                            } else { return false; }
                        } else { break; }
                    }
                    self.offset = np.offset + 1;
                    self.result.push(tar);
                    return true;
                }
            }
        }
        false
    }

    fn r_unexpresser(&mut self) -> bool {
        if self.rpick() == Some('#') && self.rpick_offset(1) == Some(':') {
            let mut np = self.rfork();
            np.offset += 2;
            if np.r_blank() && np.r_item() && np.r_blank() && np.r_call() {
                self.offset = np.offset;
                self.result.append(np.result.as_mut());
                return true;
            }
        }
        false
    }

    fn r_expr_item(&mut self) -> bool {
        if self.r_value()
        || self.r_expression()
        || self.r_set()
        || self.r_token()
        || self.r_unexpresser()
        {
            true
        } else {
            false
        }
    }

    fn r_token(&mut self) -> bool {
        if let Some(c) = self.rpick() && !_CS_N_TOKEN_HEAD.contains(c) {
            let mut chars = vec![c];
            self.offset += 1;
            while let Some(c) = self.rpick() && !_CS_N_TOKEN_BODY.contains(c) {
                chars.push(c);
                self.offset += 1;
            }
            self.push(TType::TOKEN, StringName::from(chars.into_iter().collect::<String>()).to_variant());
            true
        } else {
            false
        }
    }

    fn r_keyword(&mut self) -> bool {
        if self.rpick() == Some('&') {
            let mut chars = Vec::<char>::new();
            self.offset += 1;
            while let Some(c) = self.rpick() && !_CS_N_TOKEN_BODY.contains(c) {
                chars.push(c);
                self.offset += 1;
            }
            self.push(TType::KEYWORD, StringName::from(chars.into_iter().collect::<String>()).to_variant());
            true
        } else {
            false
        }
    }

    fn r_string(&mut self) -> bool {
        if self.rpick() == Some('"') {
            let poffset = self.offset;
            let mut chars = Vec::<char>::new();
            self.offset += 1;
            while let Some(c) = self.rpick() {
                self.offset += 1;
                match c {
                    '"' => {
                        self.push(TType::STRING, chars.into_iter().collect::<String>().to_variant());
                        return true;
                    }
                    '\\' => {
                        if let Some(nc) = self.rpick() {
                            if let Some(s) = unescape(&([c, nc].into_iter().collect::<String>())) {
                                chars.push(s.chars().nth(0).unwrap());
                            } else {
                                chars.push(c); chars.push(nc);
                            }
                            self.offset += 1;
                        } else {
                            self.offset = poffset;
                            return false;
                        }
                    }
                    _ => {
                        chars.push(c);
                    }
                }
            }
            self.offset = poffset;
            false
        } else {
            false
        }
    }

    fn r_number(&mut self) -> bool {
        let mut chars = Vec::<char>::new();
        while let Some(c) = self.rpick() && _CS_NUMBER.contains(c) {
            chars.push(c);
            self.offset += 1;
        }
        if chars.len() > 0 {
            let s = chars.into_iter().collect::<String>();
            if s == "-" {
                self.push(TType::NUMBER, (-1.0).to_variant());
            } else {
                self.push(TType::NUMBER, s.parse::<f64>().unwrap_or(0.0).to_variant());
            }
            true
        } else {
            false
        }
    }

    fn r_bool(&mut self) -> bool {
        if self.rpick() == Some('#') && let Some(c) = self.rpick_offset(1) {
            match c {
                't' => {
                    self.offset += 2;
                    self.push(TType::BOOL, true.to_variant());
                    return true;
                }
                'f' => {
                    self.offset += 2;
                    self.push(TType::BOOL, false.to_variant());
                    return true;
                }
                _ => {
                    return false;
                }
            }
        }
        false
    }

    fn r_value(&mut self) -> bool {
        if self.r_number()
        || self.r_keyword()
        || self.r_bool()
        || self.r_string() {
            true
        } else {
            false
        }
    }

    fn r_call(&mut self) -> bool {
        if self.rpick() == Some('(') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && np.r_item() {}
            np.r_blank();
            if np.rpick() == Some(')') {
                self.offset = np.offset + 1;
                if let Some(prev) = self.result.pop() {
                    let mut body = vec![prev.to_variant()];
                    body.extend(np.result);
                    self.push(TType::CALL, Array::from(body.as_slice()).to_variant());
                    return true;
                }
            }
        }
        false
    }

    fn r_array(&mut self) -> bool {
        if self.rpick() == Some('[') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && np.r_item() {}
            np.r_blank();
            if np.rpick() == Some(']') {
                self.offset = np.offset + 1;
                self.push(TType::ARRAY, np.get_result().to_variant());
                return true;
            }
        }
        false
    }

    fn r_map(&mut self) -> bool {
        if self.rpick() == Some('{') {
            let mut np = self.rfork();
            np.offset += 1;
            while np.r_blank() && np.r_item() {}
            np.r_blank();
            if np.rpick() == Some('}') {
                self.offset = np.offset + 1;
                self.push(TType::MAP, np.get_result().to_variant());
                return true;
            }
        }
        false
    }

    fn r_set(&mut self) -> bool {
        if self.r_array()
        || self.r_map()
        {
            true
        } else {
            false
        }
    }

    fn r_item(&mut self) -> bool {
        if self.r_value()
        || self.r_call()
        || self.r_set()
        || self.r_token()
        || self.r_expresser()
        {
            true
        } else {
            false
        }
    }
}

const _CS_BLANK: &str = "\u{0020}\u{0009}\u{000A}\u{000B}\u{000C}\u{00A0}\u{000D}\u{2028}\u{2029}";
const _CS_NUMBER: &str = "-0123456789.";
const _CS_N_TOKEN_HEAD: &str = concat!("&()[]{}\"$#'", "-0123456789.");
const _CS_N_TOKEN_BODY: &str = concat!("()[]{}\"'", "\u{0020}\u{0009}\u{000A}\u{000B}\u{000C}\u{00A0}\u{000D}\u{2028}\u{2029}");

impl GispParser {
    fn rpick(&self) -> Option<char> {
        self.stream.rpick(self.offset)
    }
    fn rpick_offset(&self, offset: usize) -> Option<char> {
        self.stream.rpick(self.offset + offset)
    }
    pub fn get_result(&self) -> VariantArray {
        Array::from(self.result.as_slice())
    }
}
