--Forsaken Cruel Ritual
local s,id=GetID()
function s.initial_effect(c)
	--Ritual Summon 1 "Cruel" Ritual Monster from your Deck by reducing the Levels/Ranks of monsters on the field
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	--Shuffle this card from the GY into the Deck; add 1 Ritual Monster or Ritual Spell from your Deck to your hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end
function s.thfilter(c)
	return c:IsType(TYPE_RITUAL) and (c:IsMonster() or c:IsSpell()) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToDeck() and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,c,1,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)==0 or not c:IsLocation(LOCATION_DECK|LOCATION_EXTRA) then return end
	Duel.BreakEffect()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
--Level of a monster, or Rank if it is an Xyz Monster
function s.val(c)
	if c:IsType(TYPE_XYZ) then return c:GetRank() end
	return c:GetLevel()
end
function s.matfilter(c)
	return c:IsFaceup() and c:IsMonster() and s.val(c)>0
end
function s.rfilter(c,e,tp,total)
	local lv=c:GetLevel()
	return c:IsSetCard(0x67e) and c:IsRitualMonster() and lv>0 and lv<=total
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
end
function s.total(g)
	local t=0
	for tc in g:Iter() do t=t+s.val(tc) end
	return t
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
		return #mg>0 and Duel.IsExistingMatchingCard(s.rfilter,tp,LOCATION_DECK,0,1,nil,e,tp,s.total(mg))
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.GetMatchingGroup(s.matfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,s.rfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,s.total(mg)):GetFirst()
	if not rc then return end
	local rem=rc:GetLevel()
	local used={}
	local chosen=Group.CreateGroup()
	--distribute the reduction among monsters on the field until it equals the Ritual Monster's Level
	while rem>0 do
		local pool=mg-chosen
		if #pool==0 then return end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tc=pool:Select(tp,1,1,nil):GetFirst()
		local others=s.total(pool)-s.val(tc)
		local maxv=math.min(rem,s.val(tc))
		local minv=math.max(1,rem-others)
		if minv>maxv then return end
		local amt=minv
		if maxv>minv then
			local opts={}
			for i=minv,maxv do table.insert(opts,i) end
			amt=Duel.AnnounceNumber(tp,table.unpack(opts))
		end
		chosen:AddCard(tc)
		used[tc]=amt
		rem=rem-amt
	end
	local sendg=Group.CreateGroup()
	for tc,amt in pairs(used) do
		if amt>=s.val(tc) then
			--reduced to 0: sent to the GY
			sendg:AddCard(tc)
		else
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(tc:IsType(TYPE_XYZ) and EFFECT_UPDATE_RANK or EFFECT_UPDATE_LEVEL)
			e1:SetValue(-amt)
			e1:SetReset(RESET_EVENT|RESETS_STANDARD_DISABLE)
			tc:RegisterEffect(e1)
		end
	end
	if #sendg>0 then Duel.SendtoGrave(sendg,REASON_EFFECT) end
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.BreakEffect()
	if Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
		rc:CompleteProcedure()
	end
end
