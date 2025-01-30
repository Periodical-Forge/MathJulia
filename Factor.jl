#!/usr/bin/julia
text = "6x^2 -22x -84"

# Should be able to factor out completely (including the greatest common factors)
# Should be able to factor out greatest common factors that are variables
# Should have an output of "prime" or "not factorable" for prime expressions
# Should be able to factor polynomials with leading coefficient that is not 1. 

#Tokenize Check
#Combine like terms Check
#Factor

function Tokenize(text)
    if !startswith(text, ['+', '-'])
        text = "+" * text
    end
    
    matches = eachmatch(r"[+-]?[a-zA-Z0-9^]+", text)
    tokens = [m.match for m in matches]
    
    TokensGC = Dict()
    i = 0
    for token in tokens
        TokensGC[i] = Dict()
        TokensGC[i]["token"] = token

        TokensGC[i]["variables"] = Dict()
        j = 1
        while j <= length(token)
            char = token[j]
            if isletter(char)
                var = string(char)
                exponent = 1  # Default exponent is 1
                if j < length(token) && token[j + 1] == '^'
                    j += 2  # Move to the character after ^
                    exponent_str = ""
                    while j <= length(token) && isdigit(token[j])
                        exponent_str *= token[j]
                        j += 1
                    end
                    if exponent_str != ""
                        exponent = parse(Int, exponent_str)
                    end
                else
                    j += 1
                end
                TokensGC[i]["variables"][var] = Dict("variable" => var, "exponent" => exponent)
            else
                j += 1
            end
        end

        # Handle coefficients at the start of the token, including sign
        if length(token) > 1
            # Match the optional sign and digits at the start of the token
            match_result = match(r"^([+-]?\d+)", token)
        
            if match_result !== nothing
                coefficient_str = match_result.captures[1]
                TokensGC[i]["coefficient"] = parse(Int, coefficient_str)
            else
                TokensGC[i]["coefficient"] = 1  # Default coefficient is 1
            end
        else
            TokensGC[i]["coefficient"] = 1  # Default coefficient is 1
        end
        i += 1
    end
    
    return TokensGC
end

function CombineLikeTerms(tokens)
    CLT = Dict()
    for i in keys(tokens)
        token = tokens[i]
        variables = token["variables"]
        coefficient = token["coefficient"]
        key = ""
        for var in keys(variables)
            key *= var * "^" * string(variables[var]["exponent"])
        end
        if haskey(CLT, key)
            CLT[key]["coefficient"] += coefficient
        else
            CLT[key] = Dict("coefficient" => coefficient, "variables" => variables)
        end
    end
    return CLT
end

function GreatestCommonDivisor(a, b)
    while b != 0
        a, b = b, a % b
    end
    return abs(a)
end

function GreatestCommonFactor(coefficients)
    gcf = coefficients[1]
    for coeff in coefficients[2:end]
        gcf = GreatestCommonDivisor(gcf, coeff)
    end
    return gcf
end

function Factor(tokens)
    coefficients = [tokens[key]["coefficient"] for key in keys(tokens)]
    GCF = GreatestCommonFactor(coefficients)
    
    if GCF == 1
        error("Unfactorable")
    end
    
    factored_tokens = Dict()
    for key in keys(tokens)
        token = tokens[key]
        new_coefficient = token["coefficient"] ÷ GCF
        new_key = string(new_coefficient)
        for var in keys(token["variables"])
            new_key *= var * "^" * string(token["variables"][var]["exponent"])
        end
        factored_tokens[new_key] = Dict("coefficient" => new_coefficient, "variables" => token["variables"])
    end
    
    return GCF, factored_tokens
end

function Quadratic_Roots(a, b, c)
    Δ = b^2 - 4a*c
    if Δ < 0
        error("Unfactorable")
    end
    root1 = (-b + sqrt(Δ)) / (2a)
    root2 = (-b - sqrt(Δ)) / (2a)
    return root1, root2
end

function Format(GCF, factored_tokens)
    terms = []
    for key in keys(factored_tokens)
        token = factored_tokens[key]
        if length(token["variables"]) == 1 && haskey(token["variables"], "x") && token["variables"]["x"]["exponent"] == 2
            a = token["coefficient"]
            b = 0
            c = 0
            for var in keys(token["variables"])
                if token["variables"][var]["exponent"] == 1
                    b = token["coefficient"]
                elseif token["variables"][var]["exponent"] == 0
                    c = token["coefficient"]
                end
            end
            root1, root2 = quadratic_roots(a, b, c)
            term = string("(", a, "x + ", root1, ")", "(", "x + ", root2, ")")
        else
            term = string(token["coefficient"])
            for var in keys(token["variables"])
                if token["variables"][var]["exponent"] == 1
                    term *= var
                else
                    term *= var * "^" * string(token["variables"][var]["exponent"])
                end
            end
        end
        push!(terms, term)
    end
    return string(GCF, "(", join(terms, " + "), ")")
end

TokensGC = Tokenize(text)
CLT = CombineLikeTerms(TokensGC)

#println("Combined Like Terms: ", CLT)

try
    GCF, factored_tokens = Factor(CLT)
    #println("GCF: ", GCF)
    #println("Factored Tokens: ", factored_tokens)
    Formatted_Result = Format(GCF, factored_tokens)
    println("Formatted Result: ", Formatted_Result)
catch e
    println(e)
end
