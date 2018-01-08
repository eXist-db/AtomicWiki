/**
 * Very simple basic rule set
 *
 * Allows
 *    <i>, <em>, <b>, <strong>, <p>, <div>, <a href="http://foo"></a>, <br>, <span>, <ol>, <ul>, <li>
 *
 * For a proper documentation of the format check advanced.js
 */
var wysihtml5ParserRules = {
    classes: {
        "wysiwyg-float-left": 1,
        "wysiwyg-float-right": 1,
        "wysiwyg-text-align-left": 1,
        "wysiwyg-text-align-right": 1,
        "wysiwyg-text-align-center": 1,
        "wysiwyg-text-align-justify": 1,
        "wysiwyg-img-float-left": 1,
        "wysiwyg-img-float-right": 1,
        "ext:code?lang=xquery": 1,
        "ext:code?lang=xml": 1,
        "ext:code?lang=javascript": 1,
        "ext:code?lang=css": 1,
        "ext:code?lang=text": 1,
        "ext:code?lang=plain": 1,
        "ext:code?lang=java": 1,
        "alert": 1,
        "alert-info": 1,
        "gallery:show-catalog gallery-placeholder": 1,
        "gallery:show-catalog": 1,
        "gallery:add-video video-placeholder": 1,
        "gallery:add-video": 1,
        "gallery-placeholder": 1,
        "gallery:select-video?videotyp=Pandora1": 1,
        "gallery:select-video?videotyp=Pandora2": 1,
        "gallery:select-video?videotyp=youTube": 1,
        "gallery:select-video?videotyp=vimeo": 1,
        "video-placeholder": 1,
        "gallery:add-music": 1,
        "gallery:add-music music-placeholder": 1,
        "gallery:select-music?musictyp=musicLocal": 1,
        "gallery:select-music?musictyp=musicUrl": 1,
        "gallery:select-music?musictyp=ogg": 1,
        "music-placeholder": 1
    },
  tags: {
    strong: {},
    code:   {},
    b:      {},
    i:      {},
    em:     {},
    p:      {
        "check_attributes": {
            id: "id"
        }
    },
    div:    {
        "check_attributes": {
            id: "id"
        }
    },
    span:   {},
    pre:    {
        "check_attributes": {
        }
    },
    iframe: {},
    u:      {},
    ul:     {},
    ol:     {},
    li:     {},
    h1:     {},
    h2:     {},
    h3:     {},
    figure: {},
    figcaption: {},
    a:      {
        "check_attributes": {
            href: "href"
        }
    },
    img: {
        "check_attributes": {
            src: "href",
            width: "numbers",
            height: "numbers",
            alt: "href"
        }
    },
  }
};