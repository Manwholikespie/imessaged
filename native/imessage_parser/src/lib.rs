use rustler::{Encoder, Env, NifResult, Term, Binary};
use crabstep::{TypedStreamDeserializer, deserializer::iter::Property, OutputData};

/// Helper function to extract text from NSString-like objects in the typedstream
fn extract_nsstring_text(property: &Property) -> Option<String> {
    if let Property::Object { name, data, .. } = property {
        if *name == "NSString" || *name == "NSMutableString" || *name == "NSAttributedString" {
            // Clone the iterator to explore it
            let mut data_clone = data.clone();
            while let Some(data_prop) = data_clone.next() {
                if let Property::Group(inner_group) = data_prop {
                    for inner in inner_group {
                        if let Property::Primitive(OutputData::String(s)) = inner {
                            return Some(s.to_string());
                        }
                    }
                }
            }
        }
    }
    None
}

/// Helper to detect attachment markers in parsed data
fn detect_attachments(property: &Property) -> Option<String> {
    if let Property::Object { name, data, .. } = property {
        if *name == "NSDictionary" {
            let mut data_clone = data.clone();
            while let Some(data_prop) = data_clone.next() {
                // Look for attachment-related keys
                if let Property::Group(group) = data_prop {
                    for item in group {
                        if let Some(text) = extract_nsstring_text(&item) {
                            if text.contains("__kIMFileTransferGUIDAttributeName") 
                                || text.contains("__kIMInlineMediaHeightAttributeName")
                                || text.contains("__kIMFilenameAttributeName") {
                                return Some("attachment".to_string());
                            }
                        }
                    }
                }
            }
        }
    }
    None
}

#[rustler::nif]
fn parse_typedstream<'a>(env: Env<'a>, data: Binary) -> NifResult<Term<'a>> {
    let bytes = data.as_slice();
    
    let mut deserializer = TypedStreamDeserializer::new(bytes);
    
    match deserializer.iter_root() {
        Ok(mut iter) => {
            let mut main_text: Option<String> = None;
            let mut has_attachments = false;
            let mut has_mentions = false;
            let mut has_links = false;
            
            // The first property is usually the NSAttributedString
            if let Some(property) = iter.next() {
                // Try to extract the main text
                if let Property::Group(group) = property {
                    for prop in group {
                        // Look for the main text
                        if main_text.is_none() {
                            main_text = extract_nsstring_text(&prop);
                        }
                        
                        // Look for attachments
                        if detect_attachments(&prop).is_some() {
                            has_attachments = true;
                        }
                        
                        // Check for special attributes
                        if let Property::Object { name, .. } = &prop {
                            if *name == "NSDictionary" {
                                // This might contain formatting or special attributes
                                // We'll mark these for now
                                if name.contains("Mention") {
                                    has_mentions = true;
                                }
                                if name.contains("Link") {
                                    has_links = true;
                                }
                            }
                        }
                    }
                }
            }
            
            // Continue processing remaining properties for attributes
            while let Some(property) = iter.next() {
                if let Property::Group(group) = property {
                    for prop in group {
                        if let Property::Object { name, .. } = &prop {
                            // Look for dictionaries that might contain attributes
                            if *name == "NSDictionary" {
                                // Process dictionary entries for special markers
                            }
                        }
                    }
                }
            }
            
            // Build the result as a keyword list that Elixir can understand
            let text_atom = rustler::types::atom::Atom::from_str(env, "text").unwrap();
            let attachments_atom = rustler::types::atom::Atom::from_str(env, "has_attachments").unwrap();
            let mentions_atom = rustler::types::atom::Atom::from_str(env, "has_mentions").unwrap();
            let links_atom = rustler::types::atom::Atom::from_str(env, "has_links").unwrap();
            
            let result = vec![
                (text_atom, main_text).encode(env),
                (attachments_atom, has_attachments).encode(env),
                (mentions_atom, has_mentions).encode(env),
                (links_atom, has_links).encode(env),
            ];
            
            Ok(result.encode(env))
        },
        Err(e) => {
            Err(rustler::Error::Term(Box::new(format!("Parse error: {:?}", e))))
        }
    }
}

rustler::init!("Elixir.Imessaged.TypedStream");