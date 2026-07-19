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
    pub async fn from_url(url: &str,
        #[cfg(not(feature = "reqwest"))]
        html: &str
    ) ->Option<Self> {
        let base_url: &str = &get_base_url(url);


        #[cfg(feature = "reqwest")]
        let html: &str = 
            &if AVAILABLE_SITES.iter().any(|site| has_part(base_url, site)) {
               reqwest::get(url)
                   .await
                   .ok()?
                   .text()
                   .await
                   .ok()?
            } else {
                return None;
            };
    
    
        if has_part(base_url, "amdm") {
            amdm::parse(html)
        } else if has_part(base_url, "akkords") {
            akkords::parse(html)
        } else if has_part(base_url, "5lad") {
            _5lad::parse(html)
        } else if has_part(base_url, "mytabs") {
            mytabs::parse(html)
        } else if has_part(base_url, "muzland") {
            muzland::parse(html)
        } else if has_part(base_url, "guitar-link") {
            guitar_link::parse(html)
        } else {
            None
        }
    }
}

pub fn has_part(base_url: &str, part: &str) -> bool {
    base_url.split('.').any(|p| p == part)
}
pub fn get_base_url(url: &str) -> String {
    let stripped_url: &str = 
        if url.starts_with("https://") {
            url.strip_prefix("https://").unwrap()
        } else if url.starts_with("http://") {
            url.strip_prefix("http://").unwrap()
        } else {
            url
        };
    
    let base_url = if let Some(end_index) = stripped_url.find('/') {
        &stripped_url[..end_index]
    } else { stripped_url };


    return base_url.to_string()
}
