--GodMind Shi'arWare
--Synchro: 1 Tuner + 1 or more non-Tuner monsters
--Passive 1: treated as Level 4 for the Summon of an Xyz Monster.
--Passive 2: can be used as 2 materials (Link Rating 2) for a Link Summon.
--When Special Summoned: choose 1 other "GodMind" monster in your hand / field / GY / banishment and apply its effect.
--Once per turn (Ignition): banish monsters from your hand, field and/or GY; Special Summon 1 Fusion / Synchro / Xyz / Link Monster from your
--Extra Deck (Fusion Monsters included again since 2026-11-23) whose Level / Rank / Link Rating
--is equal to or lower than the total Level / Rank / Link Rating of those monsters (a monster that is not a Link Monster counts as 1
--towards a Link Monster), as a plain Special Summon (NOT a proper Synchro / Xyz / Link Summon), then hijack it. (With "GodMind Processing Universe" face-up on your field this Ignition Effect also gets a Quick Effect clone.)
local s,id=GetID()
--"GodMind StarWare" holds the hijack code
local starware=Duel.LoadCardScript(99900011)
local SET_GODMIND=0x1650
local EFFECT_GODMIND_LINK2=99900302
function s.initial_effect(c)
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,99)
	--Passive 1: Level 4 for Xyz Summons
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_XYZ_LEVEL)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(4)
	c:RegisterEffect(e1)
	--Passive 2: counts as 2 materials for a Link Summon (read by the Link.GetLinkCount wrapper below)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_GODMIND_LINK2)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE+EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetRange(LOCATION_MZONE)
	c:RegisterEffect(e2)
	--When Special Summoned: apply the effect of a "GodMind" monster
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,0})
	e3:SetTarget(s.cptg)
	e3:SetOperation(s.cpop)
	c:RegisterEffect(e3)
	--Ignition: Tribute / banish monsters, Special Summon from the Extra Deck, hijack it
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,1})
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end
---------------------------------------------------------------------------------------------------------------------
--Passive 2. The Link Summon procedure measures materials with Link.GetLinkCount: 1 for a normal monster, or "1 or its Link Rating"
--for a Link-2+ (packed as 1+0x10000*rating). A monster with this card's effect counts as 1 or 2.
local o_GetLinkCount=Link.GetLinkCount
function Link.GetLinkCount(c)
	if c:IsHasEffect(EFFECT_GODMIND_LINK2) and not (c:IsLinkMonster() and c:GetLink()>1) then
		return 1+0x20000
	end
	return o_GetLinkCount(c)
end
---------------------------------------------------------------------------------------------------------------------
--When Special Summoned: apply the effect of a "GodMind" monster.
--Same technique as the other GodMind cards that borrow an effect: the chosen effect's target and operation run with THIS effect
--(its costs and conditions are skipped, it is "applied"), and this effect takes over its category / properties.
--Effects of one card that share an operation (the Ignition + GY + banish versions of one effect, or a Quick clone) count as one.
local LOC_COPY=LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE|LOCATION_REMOVED
local copied=nil
function s.efflist(c,e,tp,eg,ep,ev,re,r,rp)
	local list,seen={},{}
	for _,te in ipairs{c:GetCardEffect()} do
		if te:GetOwner()==c and te:IsHasType(EFFECT_TYPE_IGNITION|EFFECT_TYPE_QUICK_O|EFFECT_TYPE_TRIGGER_O|EFFECT_TYPE_TRIGGER_F) then
			local op=te:GetOperation()
			if op and not seen[op] then
				seen[op]=true
				local tg=te:GetTarget()
				if not tg or tg(e,tp,eg,ep,ev,re,r,rp,0) then table.insert(list,te) end
			end
		end
	end
	return list
end
function s.cpfilter(c,e,tp,eg,ep,ev,re,r,rp)
	return c:IsMonster() and c:IsSetCard(SET_GODMIND) and (c:IsLocation(LOCATION_HAND|LOCATION_GRAVE) or c:IsFaceup())
		and #s.efflist(c,e,tp,eg,ep,ev,re,r,rp)>0
end
function s.cptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cpfilter,tp,LOC_COPY,0,1,e:GetHandler(),e,tp,eg,ep,ev,re,r,rp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local tc=Duel.SelectMatchingCard(tp,s.cpfilter,tp,LOC_COPY,0,1,1,e:GetHandler(),e,tp,eg,ep,ev,re,r,rp):GetFirst()
	if not tc then return end
	local list=s.efflist(tc,e,tp,eg,ep,ev,re,r,rp)
	local te=list[1]
	if #list>1 then
		local opts={}
		for _,t in ipairs(list) do
			local d=t:GetDescription()
			table.insert(opts,{true,d~=0 and d or aux.Stringid(id,0)})
		end
		te=list[Duel.SelectEffect(tp,table.unpack(opts))]
	end
	copied=te
	e:SetProperty(te:GetProperty()|EFFECT_FLAG_DELAY)
	e:SetCategory(te:GetCategory())
	Duel.ClearTargetCard()
	local tg=te:GetTarget()
	if tg then tg(e,tp,eg,ep,ev,re,r,rp,1) end
end
function s.cpop(e,tp,eg,ep,ev,re,r,rp)
	local te=copied
	copied=nil
	if not te then return end
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end
---------------------------------------------------------------------------------------------------------------------
--Ignition: Tribute or banish monsters, Special Summon an Extra Deck monster of up to their total Level / Rank / Link Rating.
--Fusion Monsters are included again (2026-11-23); the Summon itself is a plain Special Summon whatever the kind (see spop)
function s.sumtype(c)
	if c:IsType(TYPE_FUSION) then return SUMMON_TYPE_FUSION end
	if c:IsType(TYPE_SYNCHRO) then return SUMMON_TYPE_SYNCHRO end
	if c:IsType(TYPE_XYZ) then return SUMMON_TYPE_XYZ end
	if c:IsType(TYPE_LINK) then return SUMMON_TYPE_LINK end
	return nil
end
--what one monster counts for: its Link Rating, Rank or Level; towards a Link Monster a non-Link monster counts as 1
function s.rating(c,forlink)
	if c:IsLinkMonster() then return c:GetLink() end
	if forlink then return 1 end
	if c:IsType(TYPE_XYZ) then return c:GetRank() end
	return c:GetLevel()
end
function s.edfilter(c,e,tp,mat)
	local st=s.sumtype(c)
	if not st then return false end
	local link=c:IsLinkMonster()
	local size=link and c:GetLink() or (c:IsType(TYPE_XYZ) and c:GetRank() or c:GetLevel())
	local total=0
	for mc in mat:Iter() do total=total+s.rating(mc,link) end
	return size>0 and size<=total and Duel.GetLocationCountFromEx(tp,tp,mat,c)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rescon(sg,e,tp,mg)
	return Duel.IsExistingMatchingCard(s.edfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,sg),false
end
function s.fincon(sg,e,tp,mg)
	return (s.rescon(sg,e,tp,mg))
end
--cost: banish monsters from your hand, field (face-up) and/or GY, in any mix, as long as their total can reach an Extra Deck monster
function s.rmfilter(c)
	return c:IsMonster() and c:IsAbleToRemoveAsCost() and (c:IsLocation(LOCATION_HAND|LOCATION_GRAVE) or c:IsFaceup())
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.rmfilter),tp,LOCATION_HAND|LOCATION_MZONE|LOCATION_GRAVE,0,c)
	if chk==0 then return #g>0 and aux.SelectUnselectGroup(g,e,tp,1,nil,s.rescon,0) end
	local mat=aux.SelectUnselectGroup(g,e,tp,1,nil,s.rescon,1,tp,HINTMSG_REMOVE,s.fincon)
	Duel.Remove(mat,POS_FACEUP,REASON_COST)
	mat:KeepAlive()
	e:SetLabelObject(mat)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local mat=e:GetLabelObject()
	if not mat then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sc=Duel.SelectMatchingCard(tp,s.edfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,mat):GetFirst()
	if sc then
		--hijacked BEFORE it is Summoned (exactly like "GodMind StarWare" does: GodMind card + rewritten references, LIGHT + Cyberse),
		--so that its own "when Special Summoned" trigger is the rewritten one
		starware.hijack(c,sc)
		starware.lightform(c,sc)
		sc:SetMaterial(mat)
		--a plain Special Summon: not a Synchro / Xyz / Link Summon, so no CompleteProcedure
		Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
	end
	mat:DeleteGroup()
	e:SetLabelObject(nil)
end
