#!/usr/bin/env bash

# Make sure exactly one filename was provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <cleaned-titanic-file>" >&2
    exit 1
fi

input="$1"

# Make sure the file exists
if [[ ! -f "$INPUT" ]]; then
    echo "Error: '$INPUT' does not exist." >&2
    exit 1
fi

# Make sure the file can be read
if [[ ! -r "$INPUT" ]]; then
    echo "Error: '$INPUT' cannot be read." >&2
    exit 1
fi

# Make sure the file is not empty
if [[ ! -s "$INPUT" ]]; then
    echo "Error: '$INPUT' is empty." >&2
    exit 1
fi


awk -F'\t' '

BEGIN {
    errors = 0
}

# ----------------------------
# Skip the header
# ----------------------------
NR == 1 {
    # There should be 5 columns
    if (NF != 5) {
        print "Error: expected 5 columns in the input file." > "/dev/stderr"
        exit 1
    }

    next
}


# ----------------------------
# Process each passenger
# ----------------------------
{
    # Check for malformed rows
    if (NF != 5) {
        printf "Warning: line %d has %d fields instead of 5. Skipping.\n", NR, NF > "/dev/stderr"
        errors++
        next
    }

    survived = tolower($2)
    gender   = tolower($3)
    age      = $4
    class    = $5


    # ----------------------------
    # Validate passenger class
    # ----------------------------

    if (class != "1st" &&
        class != "2nd" &&
        class != "3rd") {

        printf "Warning: invalid passenger class on line %d: %s\n", NR, class > "/dev/stderr"
        errors++
        next
    }


    # Count passenger
    passengers[class]++


    # ----------------------------
    # Gender counts
    # ----------------------------

    if (gender == "male") {
        males[class]++
    }
    else if (gender == "female") {
        females[class]++
    }
    else {
        unknown_gender[class]++

        printf "Warning: invalid gender on line %d: %s\n", NR, gender > "/dev/stderr"
        errors++
    }


    # ----------------------------
    # Survival information
    # ----------------------------

    if (survived == "yes" || survived == "no") {

        # Number of passengers where survival is known
        survival_known[class]++

        if (survived == "yes") {
            survived_class[class]++
        }


        # Survival by gender
        if (gender == "male" || gender == "female") {

            gender_survival_known[gender]++

            if (survived == "yes") {
                gender_survived[gender]++
            }
        }
    }


    # ----------------------------
    # Age information
    # ----------------------------

    # Only use numeric ages
    # NA values are ignored

    if (age ~ /^[0-9]+([.][0-9]+)?$/) {

        age_total[class] += age
        age_count[class]++
    }
}


# ----------------------------
# Generate report
# ----------------------------

END {

    print "Titanic Passenger Report"
    print "========================"
    print ""

    print "Passenger Information by Class"
    print "------------------------------"

    printf "%-8s %-12s %-8s %-8s %-15s %-12s\n",
           "Class",
           "Passengers",
           "Male",
           "Female",
           "Survival Rate",
           "Average Age"

    # Keep the classes in a logical order
    classes[1] = "1st"
    classes[2] = "2nd"
    classes[3] = "3rd"


    for (i = 1; i <= 3; i++) {

        c = classes[i]

        # Calculate survival rate
        if (survival_known[c] > 0) {
            survival_rate = (survived_class[c] / survival_known[c]) * 100
        }
        else {
            survival_rate = 0
        }

        # Calculate average age
        if (age_count[c] > 0) {
            average_age = age_total[c] / age_count[c]
        }
        else {
            average_age = 0
        }


        printf "%-8s %-12d %-8d %-8d %-14.2f%% %-12.2f\n",
               c,
               passengers[c],
               males[c],
               females[c],
               survival_rate,
               average_age
    }


    print ""
    print "Survival Rate Comparison"
    print "------------------------"

    print ""
    print "By Passenger Class:"

    for (i = 1; i <= 3; i++) {

        c = classes[i]

        if (survival_known[c] > 0) {
            rate = (survived_class[c] / survival_known[c]) * 100

            printf "%-8s %.2f%%\n", c, rate
        }
        else {
            printf "%-8s N/A\n", c
        }
    }


    print ""
    print "By Gender:"


    if (gender_survival_known["female"] > 0) {

        female_rate =
            (gender_survived["female"] /
             gender_survival_known["female"]) * 100

        printf "%-8s %.2f%%\n", "Female", female_rate
    }


    if (gender_survival_known["male"] > 0) {

        male_rate =
            (gender_survived["male"] /
             gender_survival_known["male"]) * 100

        printf "%-8s %.2f%%\n", "Male", male_rate
    }


    # If data problems were found,
    # return a different exit status.
    if (errors > 0) {
        exit 2
    }
}

' "$INPUT"
