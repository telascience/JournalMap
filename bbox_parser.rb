#test_arr = [
#"36°31′ to 37°20′N, 108°52′ to 109°26′E",
#"40°41′–40°46′N, 98°29′–98°50′W",
#"0°00′–0°40′S, 110°30′–111°30′E",
#"34°30′–35°30′N, 111°15′–111°45′W"
#]

## Function to convert parsed bounding box parts into coordinates that JournalMap can digest
def coord_convert(bbox)
        ## Prep latitude 1
        bbox[1]? lat1dir = bbox[1]: lat1dir = ""
        bbox[4]? lat1sec = bbox[4].to_f: lat1sec = 0
        bbox[3]? lat1min = bbox[3].to_f: lat1min = 0
        lat1deg = bbox[2].to_f + lat1min/60.0 + lat1sec/3600.0

        ## Prep latitude 2
        bbox[5]? lat2dir = bbox[5]: lat2dir = ""
        bbox[8]? lat2sec = bbox[8].to_f: lat2sec = 0
        bbox[7]? lat2min = bbox[7].to_f: lat2min = 0
        lat2deg = bbox[6].to_f + lat2min/60.0 + lat2sec/3600.0

        ## figuring out the direction/sign
        ## first, convert to just N or S
        lat1dir = lat2dir if lat1dir == ""
        lat2dir = lat1dir if lat2dir == ""
        lat1dir = lat1dir[0].upcase unless lat1dir == ""
        lat2dir = lat2dir[0].upcase unless lat2dir == ""

        ## apply direction to latitudes
        lat1deg = lat1deg * (-1) if lat1dir == "S"
        lat2deg = lat2deg * (-1) if lat2dir == "S"

        ## Prep longitude 1
        bbox[9]? lon1dir = bbox[9]: lon1dir = ""
        bbox[12]? lon1sec = bbox[12].to_f: lon1sec = 0
        bbox[11]? lon1min = bbox[11].to_f: lon1min = 0
        lon1deg = bbox[10].to_f + lon1min/60.0 + lon1sec/3600.0

        ## Prep longitude 2
        bbox[13]? lon2dir = bbox[13]: lon2dir = ""
        bbox[16]? lon2sec = bbox[16].to_f: lon2sec = 0
        bbox[15]? lon2min = bbox[15].to_f: lon2min = 0
        lon2deg = bbox[14].to_f + lon2min/60.0 + lon2sec/3600.0

        ## figuring out the direction/sign
        ## first, convert to just E or W
        lon1dir = lon2dir if lon1dir == ""
        lon2dir = lon1dir if lon2dir == ""
        lon1dir = lon1dir[0].upcase unless lon1dir == ""
        lon2dir = lon2dir[0].upcase unless lon2dir == ""

        ## apply direction to longitudes
        lon1deg = lon1deg * (-1) if lon1dir == "W"
        lon2deg = lon2deg * (-1) if lon2dir == "W"

        ## Average coordinates
        lat = (lat1deg + lat2deg)/2
        lon = (lon1deg + lon2deg)/2

        ## Return a hash with the centroid as well as the bounding box limits.
        #coord = print "#{lat1dir}, #{lat1deg}, #{lat2deg}, avg:#{lat}, by #{lon1dir}, #{lon1deg}, #{lon2deg}, avg:#{lon}"
        coord = {'centroid_lat'=>lat, 'centroid_lon'=>lon, 'lat1'=>lat1deg, 'lat2'=>lat2deg, 'lon1'=>lon1deg, 'lon2'=>lon2deg}
        return(coord)
end

test_arr = []
f = File.open("/Users/jasokarl/Dropbox/JournalMap/scripts/bounding_box_examples.txt", "r:UTF-8")
f.each_line {|line|
        # puts line
        test_arr.push line
}


## Regular expression for parsing bounding box coordinates in form of
## Latitude #1 to Latitude #2, Longitude #1 to Longitude #2
bbox_latlon_re = /
(between|about|[L|l]atitude|[L|l]at(\.)?\s)?((between|from)\s*)?   ### prepend stuff - not necessary
(?<lat1dir>N|S|[Nn]orth|[Ss]outh)?\s*   ### Latitude #1 direction (before the coord value)
(?<lat1deg>[0-9]{1,2}(\.[0-9]{1,10})?)°?\s*(?<lat1min>[0-9]{1,2}(\.[0-9]{1,10})?)?('|′|´)?\s*(?<lat1sec>[0-9]{1,2}(\.[0-9]{1,10})?)?(''|"|′′|ʺ|″)?\s*   ### Latitude #1
(\g<lat1dir>)?\s*   ### Latitude #1 direction (after the coord value)

(-|–|−|to|and|,)\s*   ### Latitude range separator

(([L|l]atitude|[L|l]at(\.)?)\s*)?   ### more fluff
(?<lat2dir>N|S|[Nn]orth|[Ss]outh)?\s*   ### Latitude #2 direction (before the coord value)
(?<lat2deg>[0-9]{1,2}(\.[0-9]{1,10})?)°\s*(?<lat2min>[0-9]{1,2}(\.[0-9]{1,10})?)?('|′|´)?\s*(?<lat2sec>[0-9]{1,2}(\.[0-9]{1,10})?)?(''|"|′′|ʺ|″)?\s*   ### Latitude #2
(\g<lat2dir>)?   ### Latitude #2 direction (after the coord value)

\s*(,|;|to|and|,\sand),?\s*((between|from)\s*)?   ### Latitude\Longitude separator

(([L|l]ongitude(s)?|[L|l]ong(\.)?)\s*)?((between|from)\s*)?   ### more fluff
(?<lon1dir>E|W|[Ee]ast|[Ww]est)?\s*   ### Longitude #1 direction (before the coord value)
(?<lon1deg>[0-9]{1,3}(\.[0-9]{1,10})?)°?\s*(?<lon1min>[0-9]{1,2}(\.[0-9]{1,10})?('|′|´))?\s*(?<lon1sec>[0-9]{1,2}(\.[0-9]{1,10})?(''|"|′′|ʺ|″))?\s*   ### Longitude #1
(\g<lon1dir>)?\s*   ### Longitude #1 direction (after the coord value)

(-|–|−|to|and|,)\s*   ### Longitude separator

(([L|l]ongitude|[L|l]ong(\.)?))?   ### more fluff
(?<lon2dir>E|W|[Ee]ast|[Ww]est)?\s*   ### Longitude #2 direction (after the coord value)
(?<lon2deg>[0-9]{1,3}(\.[0-9]{1,10})?)°\s*(?<lon2min>[0-9]{1,2}(\.[0-9]{1,10})?('|′|´))?\s*(?<lon2sec>[0-9]{1,2}(\.[0-9]{1,10})?(''|"|′′|ʺ|″))?\s*   ### Longitude #2
(\g<lon2dir>)?   ### Longitude #2 direction (after the coord value)
/x

bbox_lonlat_re = /
(([L|l]ongitude(s)?|[L|l]ong(\.)?)\s*)?((between|from)\s*)?   ### more fluff
(?<lon1dir>E|W|[Ee]ast|[Ww]est)?\s*   ### Longitude #1 direction (before the coord value)
(?<lon1deg>[0-9]{1,3}(\.[0-9]{1,10})?)°?\s*(?<lon1min>[0-9]{1,2}(\.[0-9]{1,10})?('|′|´))?\s*(?<lon1sec>[0-9]{1,2}(\.[0-9]{1,10})?(''|"|′′|ʺ|″))?\s*   ### Longitude #1
(\g<lon1dir>)?\s*   ### Longitude #1 direction (after the coord value)

(-|–|−|to|and|,)\s*   ### Longitude separator

(([L|l]ongitude|[L|l]ong(\.)?))?   ### more fluff
(?<lon2dir>E|W|[Ee]ast|[Ww]est)?\s*   ### Longitude #2 direction (after the coord value)
(?<lon2deg>[0-9]{1,3}(\.[0-9]{1,10})?)°\s*(?<lon2min>[0-9]{1,2}(\.[0-9]{1,10})?('|′|´))?\s*(?<lon2sec>[0-9]{1,2}(\.[0-9]{1,10})?(''|"|′′|ʺ|″))?\s*   ### Longitude #2
(\g<lon2dir>)?   ### Longitude #2 direction (after the coord value)

\s*(,|;|to|and|,\sand),?\s*((between|from)\s*)?   ### Latitude\Longitude separator

(between|about|[L|l]atitude|[L|l]at(\.)?\s)?((between|from)\s*)?   ### prepend stuff - not necessary
(?<lat1dir>N|S|[Nn]orth|[Ss]outh)?\s*   ### Latitude #1 direction (before the coord value)
(?<lat1deg>[0-9]{1,2}(\.[0-9]{1,10})?)°?\s*(?<lat1min>[0-9]{1,2}(\.[0-9]{1,10})?)?('|′|´)?\s*(?<lat1sec>[0-9]{1,2}(\.[0-9]{1,10})?)?(''|"|′′|ʺ|″)?\s*   ### Latitude #1
(\g<lat1dir>)?\s*   ### Latitude #1 direction (after the coord value)

(-|–|−|to|and|,)\s*   ### Latitude range separator

(([L|l]atitude|[L|l]at(\.)?)\s*)?   ### more fluff
(?<lat2dir>N|S|[Nn]orth|[Ss]outh)?\s*   ### Latitude #2 direction (before the coord value)
(?<lat2deg>[0-9]{1,2}(\.[0-9]{1,10})?)°\s*(?<lat2min>[0-9]{1,2}(\.[0-9]{1,10})?)?('|′|´)?\s*(?<lat2sec>[0-9]{1,2}(\.[0-9]{1,10})?)?(''|"|′′|ʺ|″)?\s*   ### Latitude #2
(\g<lat2dir>)?   ### Latitude #2 direction (after the coord value)
/x

bbox_pairs_re = /
(between|about|[L|l]atitude|[L|l]at(\.)?\s)?((between|from)\s*)?   ### prepend stuff - not necessary
(?<lat1dir>N|S|[Nn]orth|[Ss]outh)?\s*   ### Latitude #1 direction (before the coord value)
(?<lat1deg>[0-9]{1,2}(\.[0-9]{1,10})?)°?\s*(?<lat1min>[0-9]{1,2}(\.[0-9]{1,10})?)?('|′|´|′)?\s*(?<lat1sec>[0-9]{1,2}(\.[0-9]{1,10})?)?(''|"|′′|ʺ|″)?\s*   ### Latitude #1
(\g<lat1dir>)?\s*   ### Latitude #1 direction (after the coord value)

(,)\s*

(([L|l]ongitude(s)?|[L|l]ong(\.)?)\s*)?((between|from)\s*)?   ### more fluff
(?<lon1dir>E|W|[Ee]ast|[Ww]est)?\s*   ### Longitude #1 direction (before the coord value)
(?<lon1deg>[0-9]{1,3}(\.[0-9]{1,10})?)°?\s*(?<lon1min>[0-9]{1,2}(\.[0-9]{1,10})?('|′|´|′))?\s*(?<lon1sec>[0-9]{1,2}(\.[0-9]{1,10})?(''|"|′′|ʺ|″))?\s*   ### Longitude #1
(\g<lon1dir>)?\s*   ### Longitude #1 direction (after the coord value)

\s*(,|;|to|and|,\sand),?\s*((between|from)\s*)?   ### Latitude\Longitude separator

(([L|l]atitude|[L|l]at(\.)?)\s*)?   ### more fluff
(?<lat2dir>N|S|[Nn]orth|[Ss]outh)?\s*   ### Latitude #2 direction (before the coord value)
(?<lat2deg>[0-9]{1,2}(\.[0-9]{1,10})?)°\s*(?<lat2min>[0-9]{1,2}(\.[0-9]{1,10})?)?('|′|´|′)?\s*(?<lat2sec>[0-9]{1,2}(\.[0-9]{1,10})?)?(''|"|′′|ʺ|″)?\s*   ### Latitude #2
(\g<lat2dir>)?   ### Latitude #2 direction (after the coord value)

(,)\s*

(([L|l]ongitude|[L|l]ong(\.)?))?   ### more fluff
(?<lon2dir>E|W|[Ee]ast|[Ww]est)?\s*   ### Longitude #2 direction (after the coord value)
(?<lon2deg>[0-9]{1,3}(\.[0-9]{1,10})?)°\s*(?<lon2min>[0-9]{1,2}(\.[0-9]{1,10})?('|′|´|′))?\s*(?<lon2sec>[0-9]{1,2}(\.[0-9]{1,10})?(''|"|′′|ʺ|″))?\s*   ### Longitude #2
(\g<lon2dir>)?   ### Longitude #2 direction (after the coord value)
/x

matches = 0
test_arr.each { |test_str|
        bbox = bbox_latlon_re.match(test_str)
        bbox2 = bbox_lonlat_re.match(test_str)
        bbox3 = bbox_pairs_re.match(test_str)
        if bbox
                print ""
                # puts coord_convert(bbox)
                matches += 1
        elsif bbox2
                print ""
                # puts coord_convert(bbox2)
                matches += 1
        elsif bbox3
                puts coord_convert(bbox3)
                matches += 1
        else
                print "No match for: #{test_str}"
        end
}
pct_match = (matches.to_f/test_arr.length)
print "total matches #{pct_match}%"
