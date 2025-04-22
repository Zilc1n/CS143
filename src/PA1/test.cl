class Main inherits IO{
    num : String;
    num2 : String;
    main() : String {
        {
            if not (num = "") then {
                if not (num2 = "") then {
                    "2";
                } else 
                    "0"
                fi;
            } else
                "0"
            fi;
            "1";
        }
    };

    test() : String {
        let a1 : String <- "a1",
            a2 : String <- "a2" in {
                {
                    out_string(a1);
                    out_string("\n");
                };
        }
    };
};