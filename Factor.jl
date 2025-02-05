#!/usr/bin/julia
# text = "6x^2 -22x -84"

#text = "6x^2 -22x -84"
text = "15a^2 + 45a + 60"


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
        
        match_result = match(r"^([+-]?\d+)", token)
        if match_result !== nothing
            coefficient_str = match_result.captures[1]
            TokensGC[i]["coefficient"] = parse(Int, coefficient_str)
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

function FactorExpression(CLT)
    coefficients = [term["coefficient"] for term in values(CLT)]
    gcf = GreatestCommonFactor(coefficients)
    
    factored_terms = Dict()
    i = 1
    for key in keys(CLT)
        new_coeff = div(CLT[key]["coefficient"], gcf)
        factored_terms[i] = Dict("coefficient" => new_coeff, "variables" => CLT[key]["variables"])
        i+=1
    end
    
    return gcf, factored_terms
end

# function FindFactorPair(factored_terms)
#     a = parse(Int, match(r"-?\d+", factored_terms[1]).match)
#     b = parse(Int, match(r"-?\d+", factored_terms[2]).match)
#     c = parse(Int, match(r"-?\d+", factored_terms[3]).match)
#     ac = a * c
#     for i in 1:abs(ac)
#         if ac % i == 0
#             j = ac ÷ i
#             if i + j == b
#                 return i, j
#             elseif i - j == b
#                 return i, -j
#             elseif -i + j == b
#                 return -i, j
#             elseif -i - j == b
#                 return -i, -j
#             end
#         end
#     end
#     error("No valid factor pair found")
# end

function FindFactorPair(factored_terms)
    if length(factored_terms) == 3
        a = factored_terms[1]["coefficient"]
        b = factored_terms[2]["coefficient"]
        c = factored_terms[3]["coefficient"]
        ac = a * c
        for i in 1:abs(ac)
            if ac % i == 0
                j = ac ÷ i
                if i + j == b
                    return i, j
                elseif i - j == b
                    return i, -j
                elseif -i + j == b
                    return -i, j
                elseif -i - j == b
                    return -i, -j
                end
            end
        end
    elseif length(factored_terms) == 2
        a = factored_terms[1]["coefficient"]
        b = 0
        c = factored_terms[2]["coefficient"]
        ac = a * c
        for i in 1:abs(ac)
            if ac % i == 0
                j = ac ÷ i
                if i + j == b
                    return i, j
                elseif i - j == b
                    return i, -j
                elseif -i + j == b
                    return -i, j
                elseif -i - j == b
                    return -i, -j
                end
            end
        end
    end
end

function input()
    println("Enter the expression to be factored: ")
    text = readline()
    return text
end

function FactorEquation(factored_terms ,i, j, gcf)
    a = factored_terms[1]["coefficient"]

    ifa = GreatestCommonDivisor(i, a)
    jfa = GreatestCommonDivisor(j, a)

    i = string(div(i, ifa))
    j = string(div(j, jfa))

    a1 = div(a, ifa)
    a2 = div(a, jfa)

    if !startswith(i, ['+', '-'])
        i = "+" * i
    end
    if !startswith(j, ['+', '-'])
        j = "+" * j
    end

    if (gcf == 1)
        gcf = ""
    end
    if (a1 == 1)
        a1 = ""
    end
    if (a2 == 1)
        a2 = ""
    end

    a1 = string(a1)
    a2 = string(a2)
    
    a = gcf * "(" * a1 * "x " * i * ")(" * a2 * "x " * j * ")"
    return filter(x -> !isspace(x), a)
end

text = input()

TokensGC = Tokenize(text)
CLT = CombineLikeTerms(TokensGC)
gcf, factored_terms = FactorExpression(CLT)
try
    i, j = FindFactorPair(factored_terms)
    finals = FactorEquation(factored_terms, i, j, gcf)
    println("Factored Expression: ", finals)
catch e
end
if gcf == 1
    gcf = ""
end
global first = true
global finals = string(gcf) * "("
for token in factored_terms
    token_value = token[2]  # Access the value part of the Pair
    if token_value["coefficient"] == 1
        token_value["coefficient"] = ""
    end
    token_value["coefficient"] = string(token_value["coefficient"])
    if !startswith(token_value["coefficient"], ['+', '-']) && !first
        token_value["coefficient"] = "+" * token_value["coefficient"]
    else 
        global first = false
    end
    global finals *= string(token_value["coefficient"])
    for var in values(token_value["variables"])
        global finals *= var["variable"]
        if var["exponent"] != 1
            global finals *= "^" * string(var["exponent"])
        end
    end
end
global finals *= ")"
println("Factored Expression: ", finals)

# if length(factored_terms) == 3
#     a = parse(Int, match(r"-?\d+", factored_terms[1]).match)
#     factor1, factor2 = FindFactorPair(factored_terms)
#     i2 = GreatestCommonDivisor(factor1, a)
#     j2 = GreatestCommonDivisor(factor2, a)
#     println("Factored Expression: ", gcf, "(", i2, "x + ", div(factor1, i2), ")(", j2, "x + ", div(factor2, j2), ")")
# else
#     println("Not a quadratic trinomial, skipping factor pair check.")
# end
