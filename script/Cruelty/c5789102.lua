--Bloody Ritual of Cruelty
local s,id=GetID()
function s.initial_effect(c)
		-- Option 1: Original Ritual Proc
		local e1=Ritual.CreateProc({handler=c,lvtype=RITPROC_GREATER,filter=function(c) return c:IsRace(RACE_FIEND) and c:IsAttribute(ATTRIBUTE_DARK) end,location=LOCATION_HAND|LOCATION_GRAVE})
		c:RegisterEffect(e1)

		-- Option 2: Ritual Summon DARK Fiend by reducing levels of faceup monsters
		local e2=Effect.CreateEffect(c)
		e2:SetDescription(aux.Stringid(id,0))
		e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
		e2:SetType(EFFECT_TYPE_ACTIVATE)
		e2:SetCode(EVENT_FREE_CHAIN)
		e2:SetTarget(s.ritualtg)
		e2:SetOperation(s.ritualop)
		c:RegisterEffect(e2)
	--If this card is in your GY: You can add both this card and 1 card that mentions "Ritual of Light and Darkness" from your GY to your hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

end
s.listed_names={5789104,5789109} --Atakhan, the Cruel and Voracious
function s.thfilter(c)
	return c:IsCode(5789104,5789109) and c:IsAbleToHand()
end
s.ritual_filter=function(c)
	return c:IsRace(RACE_FIEND) and c:IsAttribute(ATTRIBUTE_DARK) and c:IsType(TYPE_RITUAL)
end

function s.ritualtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.ritual_filter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND|LOCATION_GRAVE)
end

function s.ritualop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.ritual_filter,tp,LOCATION_HAND|LOCATION_GRAVE,0,1,1,nil)
	local rc=g:GetFirst()
	if not rc then return end
	local lv=rc:GetLevel()
	local field=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if #field==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	-- Select any number of monsters whose total level reduction does not exceed the ritual monster's level
	local maxc=#field
	local selected=Duel.SelectMatchingCard(tp,Card.IsFaceup,tp,LOCATION_MZONE,LOCATION_MZONE,1,maxc,nil)
	if #selected==0 then return end
	local total_reduction=0
	local reductions={}
	for tc in aux.Next(selected) do
		local max_reduce=math.min(tc:GetLevel(),lv-total_reduction)
		if max_reduce>0 then
			-- Ask player how much to reduce for this monster
			local reduce=Duel.AnnounceNumber(tp,1,max_reduce)
			reductions[tc]=reduce
			total_reduction=total_reduction+reduce
			if total_reduction==lv then break end
		else
			reductions[tc]=0
		end
	end
	if total_reduction~=lv or not rc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true) then return end
	-- Apply reductions and send monsters with level < 1 to GY
	for tc,reduce in pairs(reductions) do
		local new_lv=tc:GetLevel()-reduce
		if new_lv<1 then
			Duel.SendtoGrave(tc,REASON_EFFECT+REASON_MATERIAL+REASON_RITUAL)
		else 
			if lv > 0 then
        local e1=Effect.CreateEffect(tc)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LEVEL)
		e1:SetValue(new_lv)
		tc:RegisterEffect(e1)
		end
	end
end
	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)
	rc:CompleteProcedure()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToHand()
		and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,c) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,2,tp,LOCATION_GRAVE)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,c)
	if #g>0 then
		g:AddCard(c)
		Duel.HintSelection(g)
		Duel.SendtoHand(g,nil,REASON_EFFECT)
	end
end