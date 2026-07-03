pub fn parse(url: &str) ->Option<crate::Song> {
    let stripped_url: &str = 
        if url.starts_with("https://") {
            url.strip_prefix("https://")?
        } else if url.starts_with("http://") {
            url.strip_prefix("http://")?
        } else {
            url
        };


    None
}
