mod amdm;
mod akkords;
mod _5lad;
mod mytabs;
mod muzland;
mod guitar_link;


pub const AVAILABLE_SITES: [&str; 6] = [
    "amdm",
    "akkords",
    "5lad",
    "mytabs",
    "muzland",
    "guitar-link",
];


impl crate::Song {
    pub fn from_url(url: &str) ->Option<Self> {
        let stripped_url: &str = 
            if url.starts_with("https://") {
                url.strip_prefix("https://")?
            } else if url.starts_with("http://") {
                url.strip_prefix("http://")?
            } else {
                url
            };
        
        let base_url = if let Some(end_index) = stripped_url.find('/') {
            &stripped_url[..end_index]
        } else { stripped_url };
    
    
        if has_part(base_url, "amdm") {
            amdm::parse(url)
        } else if has_part(base_url, "akkords") {
            akkords::parse(url)
        } else if has_part(base_url, "5lad") {
            _5lad::parse(url)
        } else if has_part(base_url, "mytabs") {
            mytabs::parse(url)
        } else if has_part(base_url, "muzland") {
            muzland::parse(url)
        } else if has_part(base_url, "guitar-link") {
            guitar_link::parse(url)
        } else {
            None
        }
    }
}

fn has_part(base_url: &str, part: &str) -> bool {
    base_url.split('.').any(|p| p == part)
}
