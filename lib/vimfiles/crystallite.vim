" Vim color file - crystallite
" Original colorscheme credit tomsik68 https://github.com/tomsik68/vim-crystallite
" Adapted for BDV use by Alan Weinstock - 2016/09/30
if version > 580
	hi clear
	if exists("syntax_on")
		syntax reset
	endif
endif

set t_Co=256
let g:colors_name = "crystallite"

"hi SignColumn -- no settings --
"hi CTagsMember -- no settings --
"hi CTagsGlobalConstant -- no settings --
hi Normal guifg=#c9c9c9 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=251 ctermbg=234 cterm=NONE
"hi CTagsImport -- no settings --
"hi CTagsGlobalVariable -- no settings --
"hi SpellRare -- no settings --
"hi EnumerationValue -- no settings --
"hi TabLineSel -- no settings --
"hi CursorLine -- no settings --
"hi Union -- no settings --
"hi TabLineFill -- no settings --
"hi CursorColumn -- no settings --
"hi EnumerationName -- no settings --
"hi SpellCap -- no settings --
"hi SpellLocal -- no settings --
"hi DefinedName -- no settings --
"hi MatchParen -- no settings --
"hi LocalVariable -- no settings --
"hi SpellBad -- no settings --
"hi Underlined -- no settings --
"hi TabLine -- no settings --
"hi clear -- no settings --
hi IncSearch guifg=#ffffff guibg=#1c303b guisp=#1c303b gui=bold,underline ctermfg=15 ctermbg=237 cterm=bold,underline
hi WildMenu guifg=#000000 guibg=#607b8b guisp=#607b8b gui=NONE ctermfg=NONE ctermbg=66 cterm=NONE
hi SpecialComment guifg=#f5ffa8 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi Typedef guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=73 ctermbg=NONE cterm=NONE
hi Title guifg=#5cacee guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=75 ctermbg=234 cterm=NONE
hi Folded guifg=#999999 guibg=#003366 guisp=#003366 gui=NONE ctermfg=246 ctermbg=17 cterm=NONE
hi PreCondit guifg=#c12869 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=1 ctermbg=234 cterm=NONE
hi Include guifg=#ccccff guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=189 ctermbg=NONE cterm=NONE
hi Float guifg=#ff2600 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=196 ctermbg=NONE cterm=NONE
hi StatusLineNC guifg=#1a1a1a guibg=#607b8b guisp=#607b8b gui=NONE ctermfg=234 ctermbg=66 cterm=NONE
hi NonText guifg=#87cefa guibg=#0f0f0f guisp=#0f0f0f gui=NONE ctermfg=117 ctermbg=233 cterm=NONE
hi DiffText guifg=#e0ffff guibg=#d74141 guisp=#d74141 gui=NONE ctermfg=195 ctermbg=167 cterm=NONE
hi ErrorMsg guifg=#ffffe0 guibg=#b22222 guisp=#b22222 gui=NONE ctermfg=230 ctermbg=124 cterm=NONE
hi Ignore guifg=#777777 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=243 ctermbg=NONE cterm=NONE
hi Debug guifg=#f5ffa8 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi PMenuSbar guifg=NONE guibg=#0f0f0f guisp=#0f0f0f gui=NONE ctermfg=NONE ctermbg=233 cterm=NONE
hi Identifier guifg=#009acd guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=38 ctermbg=234 cterm=NONE
hi SpecialChar guifg=#f5ffa8 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi Conditional guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=70 ctermbg=234 cterm=NONE
hi StorageClass guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=73 ctermbg=NONE cterm=NONE
hi Todo guifg=#00ff40 guibg=#121212 guisp=#121212 gui=NONE ctermfg=47 ctermbg=233 cterm=NONE
hi Special guifg=#f5ffa8 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi LineNr guifg=#8db6cd guibg=#0f0f0f guisp=#0f0f0f gui=NONE ctermfg=110 ctermbg=233 cterm=NONE
hi StatusLine guifg=#ff0000 guibg=#303030 guisp=#303030 gui=NONE ctermfg=196 ctermbg=236 cterm=NONE
hi Label guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=73 ctermbg=NONE cterm=NONE
hi PMenuSel guifg=#000000 guibg=#8db6cd guisp=#8db6cd gui=NONE ctermfg=NONE ctermbg=110 cterm=NONE
hi Search guifg=#ff0000 guibg=#474747 guisp=#474747 gui=NONE ctermfg=196 ctermbg=238 cterm=NONE
hi Delimiter guifg=#f5ffa8 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi Statement guifg=#ffffff guibg=#1a1a1a guisp=#1a1a1a gui=bold ctermfg=26 ctermbg=234 cterm=bold
hi Comment guifg=#468542 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=65 ctermbg=234 cterm=NONE
hi Character guifg=#c34a2c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=1 ctermbg=NONE cterm=NONE
hi Number guifg=#ff2600 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=196 ctermbg=234 cterm=NONE
hi Boolean guifg=#72a5ee guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=111 ctermbg=NONE cterm=NONE
hi Operator guifg=#bb00ff guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=129 ctermbg=234 cterm=NONE
hi Question guifg=#f4bb7e guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=222 ctermbg=234 cterm=NONE
hi WarningMsg guifg=#b22222 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=124 ctermbg=NONE cterm=NONE
hi VisualNOS guifg=#e0ffff guibg=#4682b4 guisp=#4682b4 gui=NONE ctermfg=195 ctermbg=67 cterm=NONE
hi DiffDelete guifg=#e0ffff guibg=#7e354d guisp=#7e354d gui=NONE ctermfg=195 ctermbg=95 cterm=NONE
hi ModeMsg guifg=#4682b4 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=67 ctermbg=NONE cterm=NONE
hi Define guifg=#c12869 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=196 ctermbg=NONE cterm=NONE
hi Function guifg=#ff8c00 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=208 ctermbg=234 cterm=NONE
hi FoldColumn guifg=#b0d0e0 guibg=#305070 guisp=#305070 gui=NONE ctermfg=152 ctermbg=60 cterm=NONE
hi PreProc guifg=#c12869 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=1 ctermbg=234 cterm=NONE
hi Visual guifg=#36648b guibg=#ffffff guisp=#ffffff gui=NONE ctermfg=66 ctermbg=15 cterm=NONE
hi MoreMsg guifg=#bf9261 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=137 ctermbg=NONE cterm=NONE
hi VertSplit guifg=#000000 guibg=#999999 guisp=#999999 gui=NONE ctermfg=NONE ctermbg=246 cterm=NONE
hi Exception guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=73 ctermbg=234 cterm=NONE
hi Keyword guifg=#00ffff guibg=#1a1a1a guisp=#1a1a1a gui=bold ctermfg=14 ctermbg=NONE cterm=bold
hi Type guifg=#00ffff guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=14 ctermbg=234 cterm=NONE
hi DiffChange guifg=#cc3300 guibg=#103040 guisp=#103040 gui=NONE ctermfg=166 ctermbg=23 cterm=NONE
hi Cursor guifg=#000000 guibg=#add8e6 guisp=#add8e6 gui=NONE ctermfg=NONE ctermbg=152 cterm=NONE
hi Error guifg=#ffffe0 guibg=#b22222 guisp=#b22222 gui=NONE ctermfg=230 ctermbg=124 cterm=NONE
hi PMenu guifg=#1a1a1a guibg=#607b8b guisp=#607b8b gui=NONE ctermfg=234 ctermbg=66 cterm=NONE
hi SpecialKey guifg=#63b8ff guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=75 ctermbg=NONE cterm=NONE
hi Constant guifg=#ffae00 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=202 ctermbg=234 cterm=NONE
hi Tag guifg=#f5ffa8 guibg=NONE guisp=NONE gui=NONE ctermfg=229 ctermbg=NONE cterm=NONE
hi String guifg=#a6ff00 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=154 ctermbg=234 cterm=NONE
hi PMenuThumb guifg=NONE guibg=#8db6cd guisp=#8db6cd gui=NONE ctermfg=NONE ctermbg=110 cterm=NONE
hi Repeat guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=73 ctermbg=NONE cterm=NONE
hi CTagsClass guifg=#19a3e8 guibg=NONE guisp=NONE gui=NONE ctermfg=32 ctermbg=NONE cterm=NONE
hi Directory guifg=#20b2aa guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi Structure guifg=#3b9c9c guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=73 ctermbg=NONE cterm=NONE
hi Macro guifg=#c12869 guibg=#1a1a1a guisp=#1a1a1a gui=NONE ctermfg=1 ctermbg=NONE cterm=NONE
hi DiffAdd guifg=#e0ffff guibg=#7e354d guisp=#7e354d gui=NONE ctermfg=195 ctermbg=95 cterm=NONE
hi vimhiguifgbg guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi cmakestatement guifg=#5fafd7 guibg=NONE guisp=NONE gui=NONE ctermfg=74 ctermbg=NONE cterm=NONE
hi vimhighlight guifg=#005fff guibg=NONE guisp=NONE gui=NONE ctermfg=27 ctermbg=NONE cterm=NONE
hi htmlarg guifg=#af00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=128 ctermbg=NONE cterm=NONE
hi javascriptmessage guifg=#af00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=128 ctermbg=NONE cterm=NONE
hi javaexceptions guifg=#00ffd7 guibg=NONE guisp=NONE gui=NONE ctermfg=50 ctermbg=NONE cterm=NONE
hi vimhigroup guifg=#ff005f guibg=NONE guisp=NONE gui=NONE ctermfg=197 ctermbg=NONE cterm=NONE
hi javascriptfunction guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi javastorageclass guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi cprecondit guifg=#ff00af guibg=NONE guisp=NONE gui=NONE ctermfg=199 ctermbg=NONE cterm=NONE
hi cssborderprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi mysqloperator guifg=#005fff guibg=NONE guisp=NONE gui=NONE ctermfg=27 ctermbg=NONE cterm=NONE
hi pythonbuiltin guifg=#ff5f00 guibg=NONE guisp=NONE gui=NONE ctermfg=202 ctermbg=NONE cterm=NONE
hi shcmdsubregion guifg=NONE guibg=#1a1a1a guisp=#080808 gui=NONE ctermfg=NONE ctermbg=234 cterm=NONE
hi vimfuncname guifg=#d75f00 guibg=NONE guisp=NONE gui=NONE ctermfg=166 ctermbg=NONE cterm=NONE
hi cssfontprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi pythoninclude guifg=#af00ff guibg=NONE guisp=NONE gui=NONE ctermfg=129 ctermbg=NONE cterm=NONE
hi phpidentifier guifg=#00ffff guibg=NONE guisp=NONE gui=NONE ctermfg=14 ctermbg=NONE cterm=NONE
hi pascaloperator guifg=#005faf guibg=NONE guisp=NONE gui=NONE ctermfg=25 ctermbg=NONE cterm=NONE
hi phpstringdouble guifg=#00ff00 guibg=#1c1c1c guisp=#1c1c1c gui=NONE ctermfg=10 ctermbg=234 cterm=NONE
hi javascriptstorageclass guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi vimoption guifg=#ff005f guibg=NONE guisp=NONE gui=NONE ctermfg=197 ctermbg=NONE cterm=NONE
hi javaannotation guifg=#ffff00 guibg=NONE guisp=NONE gui=NONE ctermfg=11 ctermbg=NONE cterm=NONE
hi cdefine guifg=#875fff guibg=NONE guisp=NONE gui=NONE ctermfg=99 ctermbg=NONE cterm=NONE
hi vimhigui guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi rusttrait guifg=#ff00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=200 ctermbg=NONE cterm=NONE
hi phpstatement guifg=#8700ff guibg=NONE guisp=NONE gui=NONE ctermfg=93 ctermbg=NONE cterm=NONE
hi rustexterncrate guifg=#ff00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=200 ctermbg=NONE cterm=NONE
hi htmlevent guifg=#8700ff guibg=NONE guisp=NONE gui=NONE ctermfg=93 ctermbg=NONE cterm=NONE
hi phpclass guifg=#00afff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi rustmacro guifg=#ff005f guibg=NONE guisp=NONE gui=NONE ctermfg=197 ctermbg=NONE cterm=NONE
hi shtestopr guifg=#af00ff guibg=NONE guisp=NONE gui=NONE ctermfg=129 ctermbg=NONE cterm=NONE
hi rustsigil guifg=#ffff00 guibg=NONE guisp=NONE gui=NONE ctermfg=11 ctermbg=NONE cterm=NONE
hi phpvarselector guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi shfor guifg=NONE guibg=#080808 guisp=#1a1a1a gui=NONE ctermfg=NONE ctermbg=234 cterm=NONE
hi vimhictermfgbg guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi rustenum guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi vimcommand guifg=#005fff guibg=NONE guisp=NONE gui=NONE ctermfg=27 ctermbg=NONE cterm=NONE
hi rustmodpathsep guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi htmleventdq guifg=#00ff00 guibg=NONE guisp=NONE gui=NONE ctermfg=10 ctermbg=NONE cterm=NONE
hi javaclassdecl guifg=#00afff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi rustlifetime guifg=#ffff00 guibg=NONE guisp=NONE gui=NONE ctermfg=11 ctermbg=NONE cterm=NONE
hi htmltagname guifg=#0087d7 guibg=#1a1a1a guisp=#080808 gui=NONE ctermfg=32 ctermbg=234 cterm=NONE
hi phpdefine guifg=#ff00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=200 ctermbg=NONE cterm=NONE
hi phptype guifg=#5f5fff guibg=NONE guisp=NONE gui=NONE ctermfg=63 ctermbg=NONE cterm=NONE
hi javatypedef guifg=#00afff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi htmlh1 guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi javascriptrepeat guifg=#00afff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi javascriptbraces guifg=#d75f00 guibg=NONE guisp=NONE gui=NONE ctermfg=166 ctermbg=NONE cterm=NONE
hi rustidentifier guifg=#005fff guibg=NONE guisp=NONE gui=NONE ctermfg=27 ctermbg=NONE cterm=NONE
hi shrange guifg=#ffff00 guibg=NONE guisp=NONE gui=NONE ctermfg=11 ctermbg=NONE cterm=NONE
hi htmlspecialtagname guifg=#00ffff guibg=#1a1a1a guisp=#080808 gui=NONE ctermfg=14 ctermbg=234 cterm=NONE
hi phpboolean guifg=#5f5fff guibg=NONE guisp=NONE gui=NONE ctermfg=63 ctermbg=NONE cterm=NONE
hi shderef guifg=#d75f00 guibg=NONE guisp=NONE gui=NONE ctermfg=166 ctermbg=NONE cterm=NONE
hi ruststring guifg=#00ff00 guibg=NONE guisp=NONE gui=NONE ctermfg=10 ctermbg=NONE cterm=NONE
hi cursorim guifg=#000000 guibg=#add8e6 guisp=#add8e6 gui=NONE ctermfg=NONE ctermbg=152 cterm=NONE
hi phpfunction guifg=#ff8700 guibg=NONE guisp=NONE gui=NONE ctermfg=208 ctermbg=NONE cterm=NONE
hi javascriptmember guifg=#d75f5f guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi rusttype guifg=#005fff guibg=NONE guisp=NONE gui=NONE ctermfg=27 ctermbg=NONE cterm=NONE
hi cstorageclass guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi javaconstant guifg=#875f00 guibg=NONE guisp=NONE gui=NONE ctermfg=94 ctermbg=NONE cterm=NONE
hi htmltitle guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi cmakevariablevalue guifg=#ff0087 guibg=NONE guisp=NONE gui=NONE ctermfg=198 ctermbg=NONE cterm=NONE
hi cinclude guifg=#af00ff guibg=NONE guisp=NONE gui=NONE ctermfg=129 ctermbg=NONE cterm=NONE
hi phpoperator guifg=#ffffff guibg=NONE guisp=NONE gui=NONE ctermfg=15 ctermbg=NONE cterm=NONE
hi phpstringsingle guifg=#ffff00 guibg=#1c1c1c guisp=#1c1c1c gui=NONE ctermfg=11 ctermbg=234 cterm=NONE
hi javaelementtype guifg=#00afff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi ruststorage guifg=#00ffff guibg=NONE guisp=NONE gui=NONE ctermfg=14 ctermbg=NONE cterm=NONE
hi shstatement guifg=#0087d7 guibg=NONE guisp=NONE gui=NONE ctermfg=32 ctermbg=NONE cterm=NONE
hi csspositioningprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi rustenumvariant guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi rustmodpath guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi cssbackgroundprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi cssdimensionprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi javascriptconditional guifg=#00afff guibg=NONE guisp=NONE gui=NONE ctermfg=39 ctermbg=NONE cterm=NONE
hi cssuiprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi javascriptidentifier guifg=#ff0087 guibg=NONE guisp=NONE gui=NONE ctermfg=198 ctermbg=NONE cterm=NONE
hi vimhinmbr guifg=#d78700 guibg=NONE guisp=NONE gui=NONE ctermfg=172 ctermbg=NONE cterm=NONE
hi phpmethodsvar guifg=#ff8700 guibg=NONE guisp=NONE gui=NONE ctermfg=208 ctermbg=NONE cterm=NONE
hi pascalpredefined guifg=#bcbcbc guibg=NONE guisp=NONE gui=NONE ctermfg=250 ctermbg=NONE cterm=NONE
hi csspseudoclassid guifg=#d7d75f guibg=NONE guisp=NONE gui=NONE ctermfg=185 ctermbg=NONE cterm=NONE
hi cssattrregion guifg=#87ff00 guibg=NONE guisp=NONE gui=NONE ctermfg=118 ctermbg=NONE cterm=NONE
hi phpfunctions guifg=#ff8700 guibg=NONE guisp=NONE gui=NONE ctermfg=208 ctermbg=NONE cterm=NONE
hi cincluded guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi vimhicterm guifg=#00af00 guibg=NONE guisp=NONE gui=NONE ctermfg=34 ctermbg=NONE cterm=NONE
hi cssidentifier guifg=#ff0087 guibg=NONE guisp=NONE gui=NONE ctermfg=198 ctermbg=NONE cterm=NONE
hi pythonrepeat guifg=#00d7d7 guibg=NONE guisp=NONE gui=NONE ctermfg=44 ctermbg=NONE cterm=NONE
hi csstagname guifg=#0087d7 guibg=NONE guisp=NONE gui=NONE ctermfg=32 ctermbg=NONE cterm=NONE
hi phpparent guifg=#b2b2b2 guibg=NONE guisp=NONE gui=NONE ctermfg=249 ctermbg=NONE cterm=NONE
hi javaexternal guifg=#af00ff guibg=NONE guisp=NONE gui=NONE ctermfg=129 ctermbg=NONE cterm=NONE
hi shcommandsub guifg=#ffd787 guibg=NONE guisp=NONE gui=NONE ctermfg=222 ctermbg=NONE cterm=NONE
hi javascriptstatement guifg=#af00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=128 ctermbg=NONE cterm=NONE
hi shvariable guifg=#ff0087 guibg=NONE guisp=NONE gui=NONE ctermfg=198 ctermbg=NONE cterm=NONE
hi vimhiattrib guifg=#00afd7 guibg=NONE guisp=NONE gui=NONE ctermfg=38 ctermbg=NONE cterm=NONE
hi javascriptstringd guifg=#87ff00 guibg=#080808 guisp=#080808 gui=NONE ctermfg=118 ctermbg=234 cterm=NONE
hi cmakearguments guifg=#00d700 guibg=NONE guisp=NONE gui=NONE ctermfg=40 ctermbg=NONE cterm=NONE
hi javaboolean guifg=#87ff00 guibg=NONE guisp=NONE gui=NONE ctermfg=118 ctermbg=NONE cterm=NONE
hi csstextprop guifg=#00afaf guibg=NONE guisp=NONE gui=NONE ctermfg=37 ctermbg=NONE cterm=NONE
hi mysqlkeyword guifg=#ff00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=200 ctermbg=NONE cterm=NONE
hi cssclassname guifg=#ff0087 guibg=NONE guisp=NONE gui=NONE ctermfg=198 ctermbg=NONE cterm=NONE
hi javascriptglobal guifg=#d75f5f guibg=NONE guisp=NONE gui=NONE ctermfg=167 ctermbg=NONE cterm=NONE
hi rustkeyword guifg=#00ffff guibg=NONE guisp=NONE gui=NONE ctermfg=14 ctermbg=NONE cterm=NONE
hi vimhiguirgb guifg=#ffff00 guibg=NONE guisp=NONE gui=NONE ctermfg=11 ctermbg=NONE cterm=NONE
hi shoption guifg=#87ff5f guibg=NONE guisp=NONE gui=NONE ctermfg=119 ctermbg=NONE cterm=NONE
hi htmlvalue guifg=#00ff00 guibg=NONE guisp=NONE gui=NONE ctermfg=10 ctermbg=NONE cterm=NONE
hi vimsyntype guifg=#00ffff guibg=NONE guisp=NONE gui=NONE ctermfg=14 ctermbg=NONE cterm=NONE
hi phpkeyword guifg=#ff005f guibg=NONE guisp=NONE gui=NONE ctermfg=197 ctermbg=NONE cterm=NONE
hi phprepeat guifg=#ff00d7 guibg=NONE guisp=NONE gui=NONE ctermfg=200 ctermbg=NONE cterm=NONE
hi javascopedecl guifg=#ff0087 guibg=NONE guisp=NONE gui=NONE ctermfg=198 ctermbg=NONE cterm=NONE

set background=dark
