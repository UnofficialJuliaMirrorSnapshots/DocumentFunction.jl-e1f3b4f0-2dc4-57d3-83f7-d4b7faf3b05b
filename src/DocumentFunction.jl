__precompile__()

"""
MADS: Model Analysis & Decision Support in Julia (Mads.jl v1.0) 2017

module DocumentFunction

http://mads.lanl.gov
https://github.com/madsjulia

Licensing: GPLv3: http://www.gnu.org/licenses/gpl-3.0.html
"""
module DocumentFunction

export documentfunction, getfunctionmethods, getfunctionarguments, getfunctionkeywords

"""
Redirect STDOUT to a reader
"""
function stdoutcaptureon()
	global outputoriginal = stdout;
	(outR, outW) = redirect_stdout();
	global outputread = outR;
	global outputwrite = outW;
	global outputreader = @async read(outputread, String);
end

"""
Restore STDOUT
"""
function stdoutcaptureoff()
	redirect_stdout(outputoriginal);
	close(outputwrite);
	fetch(outputreader);
	close(outputread);
	return outputreader.result
end

"""
Get function methods

Arguments:

- `f`: function to be documented

Return:

- array with function methods
"""
function getfunctionmethods(f::Function)
	m = methods(f)
	return convert(Array{String, 1}, strip.(split(string(m.mt), "\n"))[2:end])
end

function documentfunction(f::Function; location::Bool=true, maintext::String="", argtext::Dict=Dict(), keytext::Dict=Dict())
	modulename = first(methods(f)).module
	stdoutcaptureon()
	if maintext != ""
		println("**$(f)**\n")
		println("$(maintext)\n")
	end
	ms = getfunctionmethods(f)
	nm = length(ms)
	if nm == 0
		println("No methods\n")
	else
		println("Methods:")
		for i = 1:nm
			s = strip.(split(ms[i], " at "))
			m = match(r"(\[.+\]\s)(.*)", s[1]) # take string after [1..]
			methodname = m.captures[2]
			if location
				println(" - `$modulename.$(methodname)` : $(s[2])")
			else
				println(" - `$modulename.$(methodname)`")
			end
		end
		a = getfunctionarguments(f, ms)
		l = length(a)
		if l > 0
			println("Arguments:")
			for i = 1:l
				arg = strip(string(a[i]))
				print(" - `$(arg)`")
				if occursin("::", arg)
					arg = split(arg, "::")[1]
				end
				if haskey(argtext, arg)
					println(" : $(argtext[arg])")
				else
					println("")
				end
			end
		end
		a = getfunctionkeywords(f, ms)
		l = length(a)
		if l > 0
			println("Keywords:")
			for i = 1:l
				key = strip(string(a[i]))
				print(" - `$(key)`")
				if haskey(keytext, key)
					println(" : $(keytext[key])")
				else
					println("")
				end
			end
		end
	end
	stdoutcaptureoff()
end

@doc """
Create function documentation

Arguments:

- `f`: function to be documented"

Keywords:

- `maintext`: function description
- `argtext`: dictionary with text for each argument
- `keytext`: dictionary with text for each keyword
- `location`: show/hide function location on the disk
""" documentfunction

function getfunctionarguments(f::Function)
	getfunctionarguments(f, getfunctionmethods(f))
end
function getfunctionarguments(f::Function, m::Vector{String})
	l = length(m)
	mp = Array{String}(undef, 0)
	for i in 1:l
		r = match(r"(.*)\(([^;]*);(.*)\)", m[i])
		if typeof(r) == Nothing
			r = match(r"(.*)\((.*)\)", m[i])
		end
		if typeof(r) != Nothing && length(r.captures) > 1
			s = split(r.captures[2], r"(?![^)(]*\([^)(]*?\)\)),(?![^\{]*\})")
			fargs = strip.(s)
			for j in 1:length(fargs)
				if !occursin("...", string(fargs[j])) && fargs[j] != ""
					push!(mp, fargs[j])
				end
			end
		end
	end
	return sort(unique(mp))
end

@doc """
Get function arguments

Arguments:

- `f`: function to be documented"
- `m`: function methods
""" getfunctionarguments

function getfunctionkeywords(f::Function)
	getfunctionkeywords(f, getfunctionmethods(f))
end
function getfunctionkeywords(f::Function, m::Vector{String})
	# getfunctionkeywords(f::Function) = methods(methods(f).mt.kwsorter).mt.defs.func.lambda_template.slotnames[4:end-4]
	l = length(m)
	mp = Array{String}(undef, 0)
	for i in 1:l
		r = match(r"(.*)\(([^;]*);(.*)\)", m[i])
		if typeof(r) != Nothing && length(r.captures) > 2
			s = split(r.captures[3], r"(?![^)(]*\([^)(]*?\)\)),(?![^\{]*\})")
			kwargs = strip.(s)
			for j in 1:length(kwargs)
				if !occursin("...", string(kwargs[j])) && kwargs[j] != ""
					push!(mp, kwargs[j])
				end
			end
		end
	end
	return sort(unique(mp))
end

@doc """
Get function keywords

Arguments:

- `f`: function to be documented
- `m`: function methods
""" getfunctionkeywords

end
