mod amdm_ru;
mod akkords_pro;


pub const AVAILABLE_SITES: [&str; 1] = [
    "amdm.ru",
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
    
    
        if stripped_url.starts_with("amdm.ru") {
            amdm_ru::parse(url)
        } else if stripped_url.starts_with("akkords.pro") {
            akkords_pro::parse(url)
        } else {
            None
        }
    }
}
