--GodMind SuIntelligence
--Fusion: 2 "GodMind" monsters
--When this card destroys an opponent's monster by battle (once per turn): look at your opponent's Extra Deck, choose 1 Fusion/Synchro/Xyz/Link monster in it, then Special Summon it
--to your field as that kind of Summon, using materials that meet its own requirements taken from your opponent's
--hand, field, Deck, Extra Deck and/or GY (those materials are banished face-down).
--The summoned monster is then hijacked (treated as a "GodMind" card, archetype / name / Attribute / Type references rewritten).
local s,id=GetID()
--"GodMind StarWare" holds the hijack code
local starware=Duel.LoadCardScript(99900011)
local SET_GODMIND=0x1650
s.listed_series={SET_GODMIND}
s.material_setcode=SET_GODMIND
function s.initial_effect(c)
	c:EnableReviveLimit()
	--Fusion Materials: 2 "GodMind" monsters
	Fusion.AddProcMixN(c,true,true,s.matfilter,2)
	--When this card destroys an opponent's monster by battle: Special Summon 1 monster from the opponent's Extra Deck
	--using materials from their hand / field / Deck / Extra Deck / GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_BATTLE_DESTROYING)
	e1:SetCountLimit(1,id)
	e1:SetCondition(aux.bdocon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--Ignition: Special Summon 1 "Programmed Token" to your opponent's field in Defense Position, so this card has something to destroy
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOKEN+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)
end
function s.matfilter(c,fc,sumtype,tp)
	return c:IsSetCard(SET_GODMIND,fc,sumtype,tp)
end
--"Programmed Token" (LIGHT / Machine / Level 1 / ATK 0 / DEF 0)
local TOKEN_PROGRAMMED=99900014
function s.tkcheck(tp)
	return Duel.GetLocationCount(1-tp,LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp,TOKEN_PROGRAMMED,0,TYPES_TOKEN,0,0,1,RACE_MACHINE,ATTRIBUTE_LIGHT,POS_FACEUP_DEFENSE,1-tp)
end
function s.tktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return s.tkcheck(tp) end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,0)
end
function s.tkop(e,tp,eg,ep,ev,re,r,rp)
	if not s.tkcheck(tp) then return end
	local token=Duel.CreateToken(tp,TOKEN_PROGRAMMED)
	Duel.SpecialSummon(token,0,tp,1-tp,false,false,POS_FACEUP_DEFENSE)
end
---------------------------------------------------------------------------------------------------------------------
--Which kind of Summon an Extra Deck monster uses
function s.sumtype(c)
	if c:IsType(TYPE_FUSION) then return SUMMON_TYPE_FUSION,REASON_FUSION end
	if c:IsType(TYPE_SYNCHRO) then return SUMMON_TYPE_SYNCHRO,REASON_SYNCHRO end
	if c:IsType(TYPE_XYZ) then return SUMMON_TYPE_XYZ,REASON_XYZ end
	if c:IsType(TYPE_LINK) then return SUMMON_TYPE_LINK,REASON_LINK end
	return nil
end
--cheap check (used while deciding whether the effect can be activated)
function s.edfilter(c,e,tp)
	local st=s.sumtype(c)
	--never a "GodMind Processor 10²" monster (0x3650): this Summon uses the proper Summon type, which their Summoning condition would accept
	return st and c:IsFacedown() and not c:IsSetCard(0x3650) and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and c:IsCanBeSpecialSummoned(e,st,tp,false,false)
end
--cards of your opponent that can be used as material
function s.poolfilter(c,tp)
	return c:IsMonster() and (not c:IsOnField() or c:IsFaceup()) and c:IsAbleToRemove(tp,POS_FACEDOWN)
end
---------------------------------------------------------------------------------------------------------------------
--Reading the monster's material requirements.
--Fusion: the engine checks / selects Fusion Materials itself (Card.CheckFusionMaterial / Duel.SelectFusionMaterial).
--Synchro: from the parameters "Synchro.AddProcedure" stores on the card (synchro_parameters).
--Xyz: from the parameters "Xyz.AddProcedure" stores on the card (xyz_parameters).
--Link: "Link.AddProcedure" stores nothing, so its parameters are captured by running the card's setup once more with
--      every registration switched off (nothing is added to the card), and recording what it passes to Link.AddProcedure.
local linkcache={}
function s.linkparams(sc)
	local code=sc:GetOriginalCode()
	if linkcache[code]~=nil then return linkcache[code] or nil end
	local cap=false
	local mt=Duel.GetMetatable(code)
	if mt and mt.initial_effect then
		local o_add,o_reg,o_dreg,o_cnt=Link.AddProcedure,Card.RegisterEffect,Duel.RegisterEffect,Duel.AddCustomActivityCounter
		Link.AddProcedure=function(c,f,min,max,specialchk)
			if c==sc then cap={f=f,min=min or 1,max=max or c:GetLink(),chk=specialchk} end
		end
		Card.RegisterEffect=function() return 0 end
		Duel.RegisterEffect=function() end
		Duel.AddCustomActivityCounter=function() end
		pcall(mt.initial_effect,sc)
		Link.AddProcedure,Card.RegisterEffect,Duel.RegisterEffect,Duel.AddCustomActivityCounter=o_add,o_reg,o_dreg,o_cnt
	end
	linkcache[code]=cap
	return cap or nil
end
--smallest Level a card can be treated as for this Synchro Summon
local function minsynlv(c,sc)
	local v=c:GetSynchroLevel(sc)
	local a,b=v&0xffff,v>>16
	if b>0 and b<a then return b end
	return a
end
--Returns a requirement table: {fusion=true,filter=f} or {filter=f,min=n,max=n,rescon=f,finish=f}, or nil if unsupported.
function s.getreq(sc,tp)
	local st=s.sumtype(sc)
	if st==SUMMON_TYPE_FUSION then
		return {fusion=true,filter=function(c) return c:IsCanBeFusionMaterial(sc) end}
	elseif st==SUMMON_TYPE_SYNCHRO then
		local p=sc.synchro_parameters
		if sc.synchro_type~=1 or not p then return nil end
		local f1,min1,max1,f2,min2,max2=p[1],p[2] or 1,p[3] or 1,p[4],p[5] or 1,p[6] or 99
		local sumt=SUMMON_TYPE_SYNCHRO|MATERIAL_SYNCHRO
		local lv=sc:GetLevel()
		local function asT(c) return c:IsType(TYPE_TUNER,sc,sumt,tp) and (not f1 or f1(c,sc,sumt,tp)) end
		local function asN(c) return not f2 or f2(c,sc,sumt,tp) end
		local function complete(sg)
			local nT,nN,nB=0,0,0
			for c in sg:Iter() do
				local t,n=asT(c),asN(c)
				if t and n then nB=nB+1 elseif t then nT=nT+1 else nN=nN+1 end
			end
			local ok=false
			for k=math.max(min1,nT),math.min(max1,nT+nB) do
				local rest=#sg-k
				if rest>=min2 and rest<=max2 then ok=true break end
			end
			return ok and sg:CheckWithSumEqual(Card.GetSynchroLevel,lv,#sg,#sg,sc)
		end
		local function prune(sg)
			local sum,nT,nN=0,0,0
			for c in sg:Iter() do
				sum=sum+minsynlv(c,sc)
				local t,n=asT(c),asN(c)
				if t and not n then nT=nT+1 elseif n and not t then nN=nN+1 end
			end
			return sum>lv or nT>max1 or nN>max2
		end
		return {
			filter=function(c) return c:HasLevel() and c:IsCanBeSynchroMaterial(sc) and (asT(c) or asN(c)) end,
			min=min1+min2, max=math.min(max1+max2,lv),
			rescon=function(sg,e,tp,mg) return complete(sg),prune(sg) end,
			finish=function(sg,e,tp,mg) return complete(sg) end
		}
	elseif st==SUMMON_TYPE_XYZ then
		local p=sc.xyz_parameters
		if not p then return nil end
		local f,ct,maxct,exchk=p[1],p[3] or 2,p[6] or p[3] or 2,p[9]
		local function complete(sg) return #sg>=ct and #sg<=maxct and (not exchk or exchk(sg,tp,sc)) end
		return {
			filter=function(c) return c:IsCanBeXyzMaterial(sc,tp) and f(c,false,sc,tp) end,
			min=ct, max=maxct,
			rescon=function(sg,e,tp,mg) return complete(sg),#sg>maxct end,
			finish=function(sg,e,tp,mg) return complete(sg) end
		}
	elseif st==SUMMON_TYPE_LINK then
		local p=s.linkparams(sc)
		if not p then return nil end
		local sumt=SUMMON_TYPE_LINK|MATERIAL_LINK
		local link=sc:GetLink()
		local function complete(sg)
			return #sg>=p.min and #sg<=p.max and sg:CheckWithSumEqual(Link.GetLinkCount,link,#sg,#sg)
				and (not p.chk or p.chk(sg,sc,sumt,tp))
		end
		return {
			filter=function(c) return c:IsCanBeLinkMaterial(sc,tp) and (not p.f or p.f(c,sc,sumt,tp)) end,
			min=p.min, max=p.max,
			rescon=function(sg,e,tp,mg) return complete(sg),(#sg>p.max or #sg>link) end,
			finish=function(sg,e,tp,mg) return complete(sg) end
		}
	end
	return nil
end
--full check: can this monster be Summoned with materials from the pool?
function s.cansummon(sc,e,tp,pool)
	if not s.edfilter(sc,e,tp) then return false end
	local req=s.getreq(sc,tp)
	if not req then return false end
	local mg=pool:Filter(req.filter,sc) --never the chosen monster itself
	if req.fusion then return sc:CheckFusionMaterial(mg,nil,tp) end
	if #mg<req.min then return false end
	return aux.SelectUnselectGroup(mg,e,tp,req.min,req.max,req.rescon,0)
end
function s.selectmat(sc,e,tp,pool)
	local req=s.getreq(sc,tp)
	local mg=pool:Filter(req.filter,sc) --never the chosen monster itself
	--reveal the candidates that are hidden (your opponent's hand, Deck and Extra Deck), so you can see what you are picking
	local hidden=mg:Filter(Card.IsLocation,nil,LOCATION_HAND|LOCATION_DECK|LOCATION_EXTRA)
	if #hidden>0 then Duel.ConfirmCards(tp,hidden) end
	if req.fusion then return Duel.SelectFusionMaterial(tp,sc,mg,nil,tp) end
	return aux.SelectUnselectGroup(mg,e,tp,req.min,req.max,req.rescon,1,tp,HINTMSG_REMOVE,req.finish)
end
---------------------------------------------------------------------------------------------------------------------
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.edfilter,tp,0,LOCATION_EXTRA,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,1-tp,LOCATION_EXTRA)
	Duel.SetPossibleOperationInfo(0,CATEGORY_REMOVE,nil,1,1-tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_DECK|LOCATION_EXTRA|LOCATION_GRAVE)
end
--Xyz Summon: the materials are attached to the summoned monster; when they are detached (or otherwise sent to the GY) they are banished face-down instead
function s.banishcheck(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsLocation(LOCATION_GRAVE) then
		Duel.Remove(c,POS_FACEDOWN,REASON_EFFECT)
	end
end
function s.regbanish(c,owner)
	local e1=Effect.CreateEffect(owner)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_TO_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetOperation(s.banishcheck)
	e1:SetReset(RESET_EVENT|RESETS_STANDARD_EXC_GRAVE)
	c:RegisterEffect(e1,true)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ed=Duel.GetFieldGroup(tp,0,LOCATION_EXTRA)
	if #ed==0 then return end
	--look at your opponent's Extra Deck
	Duel.ConfirmCards(tp,ed)
	local pool=Duel.GetMatchingGroup(s.poolfilter,tp,0,LOCATION_HAND|LOCATION_MZONE|LOCATION_DECK|LOCATION_EXTRA|LOCATION_GRAVE,nil,tp)
	local cands=ed:Filter(s.cansummon,nil,e,tp,pool)
	if #cands==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=cands:Select(tp,1,1,nil):GetFirst()
	if not sc then return end
	local mat=s.selectmat(sc,e,tp,pool)
	if not mat or #mat==0 then return end
	local st,reason=s.sumtype(sc)
	local fromdeck=mat:IsExists(Card.IsLocation,1,nil,LOCATION_DECK)
	--hijack it BEFORE it is Summoned, and make it LIGHT + Cyberse (it is always an Extra Deck monster), so that its own
	--"when Special Summoned" trigger is the rewritten one
	starware.hijack(e:GetHandler(),sc)
	starware.lightform(e:GetHandler(),sc)
	sc:SetMaterial(mat)
	if st==SUMMON_TYPE_XYZ then
		--attach the materials to the Xyz Monster
		Duel.Overlay(sc,mat)
		for mc in mat:Iter() do
			s.regbanish(mc,e:GetHandler())
		end
	else
		Duel.Remove(mat,POS_FACEDOWN,REASON_EFFECT|REASON_MATERIAL|reason)
	end
	if fromdeck then Duel.ShuffleDeck(1-tp) end
	--their hand was shown to you while you picked the materials
	Duel.ShuffleHand(1-tp)
	Duel.BreakEffect()
	if Duel.SpecialSummon(sc,st,tp,tp,false,false,POS_FACEUP)>0 then
		sc:CompleteProcedure()
	end
end
