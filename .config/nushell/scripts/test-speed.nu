# Measure network download speed by streaming a file download.
export def main [
    url: string = "http://mirror.init7.net/archlinux/iso/latest/archlinux-x86_64.iso" # URL to download for testing speed
] {
    print "Streaming download natively and measuring performance..."
    
    # 1. Mark the start time
    let start_time = (date now)
    
    # 2. Run the stream and catch the exact total bytes directly
    let total_bytes = (http get $url | length)
    
    # 3. Mark the end time and calculate delta
    let end_time = (date now)
    let duration_seconds = (($end_time - $start_time) / 1sec)
    
    # 4. Calculate performance metrics
    let size_mb = ($total_bytes / 1_000_000)
    let mb_per_sec = ($size_mb / $duration_seconds | math round --precision 2)
    let mbps = (($mb_per_sec * 8) | math round --precision 2)
    
    print $"Target payload size resolved: ($total_bytes | into filesize)"
    print $"Finished in ($duration_seconds | math round --precision 2) seconds."
    print $"Download Speed: ($mb_per_sec) MB/s \(($mbps) Mbps\)"
}
