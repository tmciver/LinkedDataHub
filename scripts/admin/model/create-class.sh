#!/bin/bash

[ -z "$JENAROOT" ] && echo "Need to set JENAROOT" && exit 1;

args=()
super_classes=() # --super-class-of can have multiple values, so we need an array
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -b|--base)
    base="$2"
    shift # past argument
    shift # past value
    ;;
    --label)
    label="$2"
    shift # past argument
    shift # past value
    ;;
    --comment)
    comment="$2"
    shift # past argument
    shift # past value
    ;;
    --slug)
    slug="$2"
    shift # past argument
    shift # past value
    ;;
    --uri)
    uri="$2"
    shift # past argument
    shift # past value
    ;;
    --constructor)
    constructor="$2"
    shift # past argument
    shift # past value
    ;;
    --constraint)
    constraint="$2"
    shift # past argument
    shift # past value
    ;;
    --path)
    path="$2"
    shift # past argument
    shift # past value
    ;;
    --fragment)
    fragment="$2"
    shift # past argument
    shift # past value
    ;;
    --sub-class-of)
    super_classes+=("$2")
    shift # past argument
    shift # past value
    ;;
    *)    # unknown arguments
    args+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${args[@]}" # restore args

if [ -z "$base" ] ; then
    echo '-b|--base not set'
    exit 1
fi
if [ -z "$label" ] ; then
    echo '--label not set'
    exit 1
fi

args+=("-c")
args+=("${base}ns#Class") # class
args+=("-t")
args+=("text/turtle") # content type
args+=("${base}model/classes/") # container

# allow explicit URIs
if [ ! -z "$uri" ] ; then
    class="<${uri}>" # URI
else
    class="_:class" # blank node
fi

turtle+="@prefix ns:	<ns#> .\n"
turtle+="@prefix rdfs:	<http://www.w3.org/2000/01/rdf-schema#> .\n"
turtle+="@prefix ldt:	<https://www.w3.org/ns/ldt#> .\n"
turtle+="@prefix dct:	<http://purl.org/dc/terms/> .\n"
turtle+="@prefix foaf:	<http://xmlns.com/foaf/0.1/> .\n"
turtle+="@prefix dh:	<https://www.w3.org/ns/ldt/document-hierarchy/domain#> .\n"
turtle+="@prefix spin:	<http://spinrdf.org/spin#> .\n"
turtle+="${class} a ns:Class .\n"
turtle+="${class} rdfs:label \"${label}\" .\n"
turtle+="${class} foaf:isPrimaryTopicOf _:item .\n"
turtle+="${class} rdfs:isDefinedBy <../ns/domain#> .\n"
turtle+="_:item a ns:ClassItem .\n"
turtle+="_:item dct:title \"${label}\" .\n"
turtle+="_:item foaf:primaryTopic ${class} .\n"

if [ ! -z "$comment" ] ; then
    turtle+="${class} rdfs:comment \"${comment}\" .\n"
fi
if [ ! -z "$slug" ] ; then
    turtle+="_:item dh:slug \"${slug}\" .\n"
fi
if [ ! -z "$constructor" ] ; then
    turtle+="${class} spin:constructor <$constructor> .\n"
fi
if [ ! -z "$constraint" ] ; then
    turtle+="${class} spin:constraint <$constraint> .\n"
fi
if [ ! -z "$path" ] ; then
    turtle+="${class} ldt:path \"${path}\" .\n"
fi
if [ ! -z "$fragment" ] ; then
    turtle+="${class} ldt:fragment \"${fragment}\" .\n"
fi

for sub_class_of in "${super_classes[@]}"
do
    turtle+="${class} rdfs:subClassOf <$sub_class_of> .\n"
done

# set env values in the Turtle doc and sumbit it to the server

# make Jena scripts available
export PATH=$PATH:$JENAROOT/bin

# submit Turtle doc to the server
echo -e "$turtle" | turtle --base="${base}" | ../../create-document.sh "${args[@]}"