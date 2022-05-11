load("@ytt:data", "data")
load("@ytt:yaml", "yaml")
load("@ytt:regexp", "regexp")

def fixup_workshop_resource(obj, pattern, replacement):
    def fixup_resource(obj):
        if type(obj) == "string":
            return regexp.replace(pattern, obj, replacement).format(**data.values)
        elif type(obj) == "dict":
            return {k: fixup_resource(v) for k, v in obj.items()}
        elif type(obj) == "list":
            return [fixup_resource(v) for v in obj]
        else:
            return obj
        end
    end
    return fixup_resource(obj)
end

def fixup_workshop_file(filename, pattern, replacement):
    return fixup_workshop_resource(yaml.decode(data.read(filename)), pattern, replacement)
end
